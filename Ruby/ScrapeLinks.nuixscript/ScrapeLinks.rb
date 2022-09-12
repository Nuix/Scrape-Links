# Menu Title: Scrape Links
# Needs Case: true
# Needs Selected Items: false

# Bootstrap Nx library
require_relative "Nx.jar"
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "java.util.regex.Pattern"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

require_relative "EmlScraper.rb"

# Build settings dialog
dialog = TabbedCustomDialog.new("Scrape Links")
# This makes it so script remembers settings last used
dialog.enableStickySettings(File.join(File.dirname(__FILE__),"RecentSettings.json"))
# Link back to GitHub
dialog.setHelpUrl("https://github.com/Nuix/Scrape-Links")

main_tab = dialog.addTab("main_tab","Main")
main_tab.appendDirectoryChooser("temp_directory","EML Temp Export Directory")

items_were_selected = (!$current_selected_items.nil? && $current_selected_items.size > 0)
if items_were_selected
	main_tab.appendRadioButton("use_selected_emails","Use #{$current_selected_items.size} Selected Items","input_group",true)
	main_tab.appendRadioButton("use_all_emails","All Emails","input_group",false)
else
	main_tab.appendHeader("No items selected, all emails will be processed.")
end

annotation_tab = dialog.addTab("annotation_tab","Annotations")
annotation_tab.appendCheckBox("tag_items","Tag Items with URLs",true)
annotation_tab.appendTextField("tag_name","Tag Name","Scraped Links")
annotation_tab.enabledOnlyWhenChecked("tag_name","tag_items")

annotation_tab.appendTextField("errored_tag_name","Tag Errored Items with","Scraped Links|Error")

annotation_tab.appendSeparator("")
annotation_tab.appendCheckBox("apply_custom_metadata","Apply Custom Metadata",true)
annotation_tab.appendTextField("custom_field_name","Field Name","Scraped Links")
annotation_tab.enabledOnlyWhenChecked("custom_field_name","apply_custom_metadata")

filter_tab = dialog.addTab("filter_tab","URL Match Filters")
filter_tab.appendCheckBox("perform_filtering","Perform Filtering",false)
filter_tab.appendHeader("Only URLs which also match on of these regular expressions will be reported when 'Perform Filtering' is checked.")
default_filters = [
	"https?://[^\\.]+\\.google\\.com",
]
filter_tab.appendStringList("url_filters",default_filters)
filter_tab.enabledOnlyWhenChecked("url_filters","perform_filtering")

regex_tab = dialog.addTab("regex_tab","URL Regex")
regex_tab.appendHeader("This is a Java regular expression used to locate URLs in EML contents.  Most likely you will want to leave this as is.")
regex_tab.appendTextArea("url_regex","","(mailto|http|https|ftp)\\://[a-zA-Z0-9\\-\\.]+\\.[a-zA-Z]{2,3}(:[a-zA-Z0-9]*)?/?([a-zA-Z0-9\\-\\._\\?\\,\\'/\\\\\\+&amp;%\\$#\\=~])*[^\\.\\,\\)\\(\\s\\\"]")
# lets make text area monospaced font
java_import java.awt.Font
dialog.getControl("url_regex").setFont(Font.new("Consolas",Font::PLAIN,12))

dialog.validateBeforeClosing do |values|
	if values["perform_filtering"] && values["url_filters"].size < 1
		CommonDialogs.showWarning("Please provide at least 1 URL filter")
		next false
	end

	if values["tag_items"] && values["tag_name"].strip.empty?
		CommonDialogs.showWarning("Please provide value for 'Tag Name'.")
		next false
	end

	if values["errored_tag_name"].strip.empty?
		CommonDialogs.showWarning("Please provide value for 'Errored Tag Name'.")
		next false
	end

	# Get user confirmation about closing all workbench tabs
	if values["apply_custom_metadata"] && CommonDialogs.getConfirmation("The script needs to close all workbench tabs, proceed?") == false
		next false
	end

	next true
end

dialog.display
if dialog.getDialogResult == true
	ProgressDialog.forBlock do |pd|
		pd.setTitle("Scrape Links")
		pd.setSubProgressVisible(false)
		pd.setAbortButtonVisible(false)

		# Get values from settings dialog		
		values = dialog.toMap
		temp_directory = values["temp_directory"]
		url_regex = Pattern.compile(values["url_regex"],Pattern::CASE_INSENSITIVE)
		apply_custom_metadata = values["apply_custom_metadata"]
		custom_field_name = values["custom_field_name"]
		use_selected_emails = values["use_selected_emails"]
		url_filters = values["url_filters"]
		perform_filtering = values["perform_filtering"]
		errored_tag_name = values["errored_tag_name"]

		if perform_filtering
			EmlScraper.filter_regexes = url_filters.map{|f| Pattern.compile(f,Pattern::CASE_INSENSITIVE) }
		end

		# Obtain the items we will be using, either by searching for all emails
		# or filtering the user's selection to just emails
		items = nil
		if use_selected_emails
			pd.logMessage("Filtering selection to emails...")
			items = $current_selected_items.select{|i|i.getKind.getName == "email"}
			pd.logMessage("Found #{items.size} emails in selection")
		else
			pd.logMessage("Searching case for emails...")
			items = $current_case.search("kind:email")
			pd.logMessage("Found #{items.size} emails")
		end

		# Good idea to close all tabs when applying custom metadata
		pd.setMainStatusAndLogIt("Closing all tabs to prevent errors (since you are applying custom metadata)")
		if apply_custom_metadata
			$window.closeAllTabs
		end

		# Only need to do this step if the use wanted to filter urls based on secondary list of
		# regular expressions
		if perform_filtering
			pd.setMainStatusAndLogIt("Building filter regular expressions...")
			filter_regexes = url_filters.map{|n|Pattern.compile(n,Pattern::CASE_INSENSITIVE)}
		end

		session = javax.mail.Session.getDefaultInstance(java.lang.System.getProperties,nil)
		email_exporter = $utilities.getEmailExporter
		items_to_tag = []
		passing_url_count = 0
		java.io.File.new(temp_directory).mkdirs

		pd.setMainProgress(0,items.size)
		pd.setMainStatusAndLogIt("Scanning Items...")
		pd.setAbortButtonVisible(true)

		errored_item_count = 0

		items.each_with_index do |item,index|
			break if pd.abortWasRequested
			pd.setMainProgress(index+1,items.size)
			pd.setMainStatus("Scanning Items (#{index+1}/#{items.size})")

			begin
				temp_file = java.io.File.new(File.join(temp_directory,"#{item.getGuid}.eml"))
				email_exporter.exportItem(item,temp_file,{
					"format" => "eml",
					"includeAttachments" => false,
				})

				found_urls = EmlScraper.scrape_urls(temp_file)
				if found_urls.size > 0
					items_to_tag << item
					passing_url_count += found_urls.size
					if apply_custom_metadata
						item.getCustomMetadata[custom_field_name] = found_urls.join("; ")
					end
				end
				pd.setSubStatus("Passing URLs Found: #{passing_url_count}")
				temp_file.delete
			rescue Exception => exc
				pd.logMessage("Error while scraping item with GUID #{item.getGuid}: #{exc.message} (Nuix log contains stacktrace)")
				puts "Error while scraping item with GUID #{item.getGuid}: #{exc.message}\n#{exc.backtrace.join("\n")}"
				pd.logMessage("Applying error tag '#{errored_tag_name}' to item...")
				item.addTag(errored_tag_name)
				errored_item_count += 1
			end
		end

		# Tag all the items in which we found URLs
		if values["tag_items"] && !pd.abortWasRequested
			pd.setMainStatusAndLogIt("Tagging Items...")
			if items_to_tag.size > 0
				$utilities.getBulkAnnotater.addTag(values["tag_name"],items_to_tag)
				pd.logMessage("Tagged: #{items_to_tag.size}")
			else
				pd.logMessage("There were no items to tag")
			end
		end

		# Delete the temp directory we created earlier
		pd.setMainStatusAndLogIt("Deleting temporary export directory...")
		org.apache.commons.io.FileUtils.deleteDirectory(java.io.File.new(temp_directory))

		pd.logMessage("Errored Item Count: #{errored_item_count}")
		if errored_item_count > 0
			pd.logMessage("!!! Review errored items by searching for tag: #{errored_tag_name}")
		end
		
		# Finalize the progress dialog
		pd.logMessage("Passing URLs Found: #{passing_url_count}")
		if pd.abortWasRequested
			pd.setMainStatusAndLogIt("User Aborted")
		else
			pd.setCompleted
		end
		
		# Open a new workbench tab for the user
		query = nil
		if values["tag_items"] && items_to_tag.size > 0
			query = "tag:\"#{values["tag_name"]}\""
		else
			query = "guid:(#{items.map{|i|i.getGuid}.join(" OR ")})"
		end

		$window.openTab("workbench",{:search=>query})
	end
end
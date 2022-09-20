class EmlScraper
	def self.filter_regexes=(value)
		@filter_regexes = value
	end

	def self.filter_regexes
		@filter_regexes = [] if @filter_regexes.nil?
		return @filter_regexes
	end

	def self.url_capture_regex=(value)
		if value.is_a?(String)
			value = /(#{value})/
		end
		@url_capture_regex = value
	end

	def self.url_capture_regex
		return @url_capture_regex
	end

	def self.scrape_urls(eml_file)
		@filter_regexes = [] if @filter_regexes.nil?
		found_urls = {}
		mime_message = build_mime_message(eml_file)
		if mime_message.isMimeType("multipart/*")
			mime_multi_part = mime_message.getContent
			scrape_urls_multipart(mime_multi_part).each{|key|found_urls[key]=true}
		end
		return found_urls.keys
	end

	def self.scrape_urls_multipart(mime_multi_part)
		found_urls = {}
		mime_multi_part.getCount.times do |i|
			body_part = mime_multi_part.getBodyPart(i)
			if body_part.isMimeType("text/html")
				scrape_urls_html(body_part).each{|key|found_urls[key]=true}
			elsif body_part.isMimeType("text/plain") && !@url_capture_regex.nil?
				scrape_urls_plain(body_part).each{|key|found_urls[key]=true}
			elsif body_part.isMimeType("multipart/*")
				scrape_urls_multipart(body_part.getContent).each{|key|found_urls[key]=true}
			end
		end
		return found_urls.keys
	end

	def self.scrape_urls_html(body_part)
		found_urls = {}
		get_link_urls(body_part).each do |url|
			found_urls[url] = true
		end
		return found_urls.keys
	end

	def self.scrape_urls_plain(body_part)
		found_urls = {}
		text = body_part.getContent
		text.scan(@url_capture_regex).each do |matched_url|
			puts matched_url.inspect
			found_urls[matched_url[0]] = true
		end
		return found_urls.keys
	end

	def self.build_mime_message(eml_file)
		fis = java.io.FileInputStream.new(eml_file)
		session = javax.mail.Session.getInstance(java.lang.System.getProperties)
		mime_message = javax.mail.internet.MimeMessage.new(session,fis)
		fis.close
		return mime_message
	end

	def self.get_link_urls(body_part)
		found_urls = {}
		html = body_part.getContent
		doc = org.jsoup.Jsoup.parse(html)
		links = doc.select("a[href]")
		links.each do |link|
			href = link.attr("href")
			if @filter_regexes.size > 0
				@filter_regexes.each do |filter|
					# Filter found URL
					if filter.matcher(href).find
						found_urls[href] = true
						break
					end
				end
			else
				found_urls[href] = true
			end
		end
		return found_urls.keys
	end
end
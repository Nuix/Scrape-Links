
Scrape Links
============

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) ![This script was last tested in Nuix 9.10](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-9.10-green.svg)

View the GitHub project [here](https://github.com/Nuix/Scrape-Links) or download the latest release [here](https://github.com/Nuix/Scrape-Links/releases).

# Overview

**Written By:** Jason Wells

The body of an email may contain HTML hyper links.  The text captured by Nuix upon loading these emails will contain the link's displayed text, which may not contain the link's URL.  Take this contrived example of an HTML email body:

```html
Hey Jason,

	Check out <a href="http://www.github.com/Nuix">this website</a>.  There are a bunch of Nuix scripts there.
```

The text only rendering of this may look like the following:

```
Hey Jason,

	Check out this website.  There are a bunch of Nuix scripts there.
```

The link's display text is preserved, but the URL it linked to is not.

Each email is exported as an EML file to a temporary location.  The EML is then parsed/loaded into a [javax.mail.MimeMessage](https://javaee.github.io/javaee-spec/javadocs/javax/mail/internet/MimeMessage.html).  The body content parts are then iterated:
- If a body content part is `text/html` then the body is further parsed by [Jsoup](https://jsoup.org/).  Against that a query for `a[href]` is ran and for each link the `href` value is captured.
- If a body content part is `text/plain` then the URL regular expression is ran across its text to capture any URLs not in a link's `href` attribute.

The parsed URLs can optionally be filtered further to just those of interest based on additional filter regular expressions you provide.  This could be used for example to only list URLs that link to a particular set of websites, etc.

# Getting Started

## Setup

Begin by downloading the latest release.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Settings

- **Main Tab**
	- **Temp Export Directory**: Location where temporary EML files will be exported to for inspection.
	- **Use Selected Emails**: If items were selected when the script was ran this allows you to specify using the selected items as input.
	- **All Emails**: If items were selected when the script was ran this allows you to specify to use all emails in the case (`kind:email`) instead of the items selected as input.  If no items were selected when the script is ran, this will not be an option, the script will just use all emails in the case.
- **Annotation Tab**
	- **Tag Items with URLs**: When checked, each item which is found to have at least one URL which passes at least one of the provided filters will be tagged.
	- **Tag Name**: If you are applying tags, this is the tag which will be applied to those items.
	- **Apply Custom Metadata**: When checked, each items which is found to have at least one passing URL will have a custom metadata field applied containing all the passing URLs joined and delimited by `; `.
	- **Field Name**: If applying custom metadata, this is the name of the custom metadata field to be applied.
- **URL Match Filters Tab**
    - **Perform Filtering**: Whether to perform a secondary filtering pass on URLs located in EMLs.  This can allow you to filter to particular domains for example.  Un-check to report all URLs found.
    - Listing of Java regular expressions that are used to filter which found URLs are recorded.  When **Perform Filtering** is checked, only URLs that match one of the provided regular expressions will be reported.
- **URL Regex**: The regular expression which will be used to locate URLs within each EML's contents.  In most cases, you can leave this as is.

# Cloning this Repository

This script relies on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the script.

# License

```
Copyright 2022 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

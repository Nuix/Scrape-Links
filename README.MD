
Scrape Links
============

![Last tested in Nuix 7.4](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Scrape-Links) or download the latest release [here](https://github.com/Nuix/Scrape-Links/releases).

# Overview

**Written By:** Jason Wells

The body of an email may contain HTML hyper links.  The text captured by Nuix upon loading these emails will contain the link's displayed text, which may not contain the link's URL.

This script scrapes URLs from emails by first exporting them to a temporary location as EML files.  Since EML files are essentially a structured text format, this script is then able to use a regular expression to parse out URLs within each email.  The parsed URLs are then filtered to just those of interest based on additional filter regular expressions you provide.

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
    - **Perform Filtering**: Whether to perform a secondary filtering pass on URLs located in EMLs.  This can allow you to filter to particular domains for example.  Un-check to get all URLs found.
    - Listing of Java regular expressions that are used to filter which found URLs are recorded (considered as "passing").
- **URL Regex**: The regular expression which will be used to locate URLs within each EML's contents.

# License

```
Copyright 2018 Nuix

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

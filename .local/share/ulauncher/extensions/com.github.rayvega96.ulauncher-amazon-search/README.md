# Amazon Search Ulauncher extension

This extention provides you a quick search on your favorite amazon website with 3 useful more options:
- Search on every country's amazon website;
- Scrape the five most rated results;
- Open up your most used amazon profile pages in a glimp

![screenshot](/readme_images/simple_search.png)

## Prerequisites

This extension uses **python3 library beautiful-soup4** for the FastSearch option. Be sure to have installed it before launching the extension.
Copy and paste this on your terminal:

```
pip3 install beautifulsoup4
```

## Install

After you have installed Ulauncher, go to **preferences window > extensions > add extension** and paste the following url:

```
https://github.com/rayvega96/ulauncher-amazon-search
```

## Available commands

In the Ulauncher Amazon Search **preferences window** you can:

- Set up your main Amazon website

![screenshot](/readme_images/simple_search.png)

- Enable/Disable research on every amazon website by using -*domain parameter*

![screenshot](/readme_images/location_search.png)

- Enable/Disable the use of *-my profile -myorders -mymessages -mybalance* parameters;

![screenshot](/readme_images/all_fast_commands.png)

- Enable/Disable FastSearch for a fast scraping of the 5 most rated results of your query.

![screenshot](/readme_images/fastsearch.png)

**You can also use these commands together!**

![screenshot](/readme_images/fast_commands_with_location.png)

*Using profile parameters with domain research*

![screenshot](/readme_images/fast_search_with_location.png)

*Using FastSearch with domain research*

## All website domains

- -it  for Amazon Italy
- -uk  for Amazon United Kingdom
- -sp  for Amazon Spain
- -nl  for Amazon Netherlands
- -us  for Amazon United States
- -mx  for Amazon Mexico
- -ca  for Amazon Canada
- -ge  for Amazon Germany
- -fr  for Amazon France
- -jp  for Amazon Japan
- -br  for Amazon Brazil
- -au  for Amaozn Australia
- -in  for Amazon India
- -cn  for Amazon China


## Possible bugs and errors

Since I built this extension in 3 days, you may find some bugs. In that case, You can report it and when I have time I'll try to fix it.

## FAQ

1.Q) Why doesn't FastSearch work?

1.A) Sometimes too much researches may break the extension. Try to clean Ulauncher cache situated in: ``` ~\.cache\ ```

2.Q) Why I constantly get 503 Error while using FastSearch?

2.A) FastSearch is a webscraper function and sometimes it will give you 503 error because Amazon is preventing flooding from your IP. In this case you just have to wait a bit before using it again. You can also try to increase the number of seconds for waiting a response in the extension preferences.

3.Q) Why does FastSearch not always work with books?

3.A) Because the scraping method used in this extension is based on normal products and not in multiple-category products like books.

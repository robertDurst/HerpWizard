# Scraping

`scraper.rb` is the base class.

## Sources

* [iNaturalist](https://api.inaturalist.org/v1/docs/#!/Observations/get_observations)
* [Field Herp Forum](https://www.fieldherpforum.com/forum/viewforum.php?f=2)

## Qualifying Information

Each source will be _more-or-less_ objective and _more-or-less_ reputable. Objectivity will be reserved for anything that is _published_ and undergoes some sort of review process: research paper, books, etc. Subjectivity will be reserved for forums and self posted observations: iNaturalist, blogs, etc. Beyond this, we will (by hand) rate each source. For this we can either do a blanket score across a single source or try to leverage internal information like a user's reputation (on the site) and/or how active they are.

We will also probably want to weight the completeness of information. As an example, an iNaturalist observation with "all fields" is worth a bit more than an observation with few upvotes, few pictures, and an obscured location.

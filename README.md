# API

This application is a Rails API application that serves up information to those who wish to use it. Currently this application only supports querying Library Hours that are Managed in Alma.

# Setup (Docker)

This application uses docker. To set up the application, simply run
`docker-compose build && docker-compose up`

# Setup (Puma/Rails)

This application uses:
`Ruby Version 2.5.1`

First run `bundle install`
then run `rails s`

# Querying the API

To query the API, make a POST request to api.library.oregonstate.edu

## Hours

To query the HOURS, follow the steps from "Querying the API" to the route `/hours.json`
The API can accept no data and it will query for the current day.
The API can accept a single date ["2018-07-18"] and it will return the hours for that date.
The API can accept an array of dates ["2018-07-18", "2018-07-22"] and it will return the hours from the first date to the last date.

# Return value

The API will return a JSON object which looks like:
```
{ open: "12:00am",
  close: "12:00am",
  string_date: "Fri, Jun 12, 2018",
  sortable_date: "2018-06-12",
  formatted_hours: "Open all day",
  open_all_day: true,
  closes_at_night: false,
  event_desc: "",
  event_status: ""
}

event_desc is the description of any special events found for a date or range of dates given. 
event_status describes whether or not the library is open or closed

the key to this JSON Object is `2018-06-12T00:00:00+00:00`

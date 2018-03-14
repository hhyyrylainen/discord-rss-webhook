# discord-rss-webhook
Reads RSS feeds and posts them to a discord webhook

Database setup
==============

You need a postgresql database that accepts unix domain socket
connections with the current username. And with database creation
rights (or you can manually create the required database)

To set the rights use `ALTER USER currentusername CREATEDB;`. After
creating the user with `CREATE USER currentusername`.

#!/usr/bin/env ruby
# coding: utf-8
# Main file of this project
# Written by Henri Hyyryläinen
require 'logger'
require 'open-uri'
require 'feedparser'

require 'discordrb'
require 'discordrb/api'
require 'discordrb/webhooks'

# Configuration
require_relative 'config'
require_relative 'database'

# Suppress tons of messages
LogUtils::Logger[FeedParser::Parser].level = Logger::INFO

puts "Verifying database"

verifyDatabasesAndTablesExist

puts "Starting RSS feed to discord webhook bot"

$runFeeds = true

Signal.trap("INT") {
  
  $runFeeds = false
  $feedThread.wakeup
}

$feedThread = Thread.new {

  while $runFeeds
    items = []
    
    puts "Fetching feeds..."

    Feeds.each{|feedInfo|

      feedParser = FeedParser::Parser.parse(open(feedInfo).read)
      items += feedParser.items
    }

    # Skip handling the items if we should quit
    if !$runFeeds
      break
    end

    items.each{|item|

      # Check is it already sent
      puts "Handling item '#{item.id}'"

      if checkHasPostBeenSent item.id
        puts "It's already sent"
        next
      end

      formatted = "New post by #{item.author.to_s.split(' ')[0]} in topic "+
                  "#{item.title}\n#{item.url}"      
      
      puts "Sending item to discord: " + formatted

      # This is a hacky way to follow the rate limiting
      builder = Discordrb::Webhooks::Builder.new

      builder.content = formatted
      if CustomUserName
        builder.username = CustomUserName
      end

      # Send it
      # could append ?wait=true to the url
      response = Discordrb::API::request(:webhook, WebhookMajorParameter, "post", WebhookURL,
                                         builder.to_json_hash.to_json, content_type: :json)

      puts "Got response: #{response.code}"

      if response.code != 200 && response.code != 204
        
        # Failed
        puts "Request failed. Not marking as done"

      else
        # Mark item as done
        puts "Marking item as done"
        setPostAsSent item.id, item.url
        
      end
    }

    puts "Done handling feeds. Waiting for next run"

    # And allow quitting before waiting
    if !$runFeeds
      break
    end
    
    sleep UpdateEveryNSeconds
  end

  puts "Ended feed parsing thread"
}

$feedThread.join


# Handles database things
require 'pg'

# Configuration (this has the database credentials also)
require_relative 'config'

DATABASE_NAME = "discord-rss-webhook"
DATABASE_VERSION = 1

$dbConnection = nil

def openConnectionIfNotOpen
  return if $dbConnection && $dbConnection.status() == :CONNECTION_OK

  $dbConnection = PG.connect(dbname: DATABASE_NAME)
end

def _verifyDBExists
  begin
    openConnectionIfNotOpen
  rescue PG::ConnectionBad => e
    if e.message =~ /database "#{DATABASE_NAME}".*does not exist/i
      puts "Database is missing. Attempting to create"
      conn = PG.connect(dbname: 'postgres')
      conn.exec("CREATE DATABASE #{conn.quote_ident(DATABASE_NAME)};")
      conn.close()
      puts "Created database"
    else
      raise
    end
  end
end

def _verifyTableVersions

  result = $dbConnection.exec("SELECT value FROM config WHERE key = 'version';")

  if result.ntuples != 1
    puts "Database doesn't have a version specified. Inserting version '#{DATABASE_VERSION}'"

    $dbConnection.exec_params("INSERT INTO config (key, value) VALUES ('version', $1);",
                              [DATABASE_VERSION.to_s])
  else
    version = result[0]["value"].to_i

    if version != DATABASE_VERSION
      abort("DATABASE_VERSION has changed. Now: #{DATABASE_VERSION} db version: "+
            "#{version}. TODO: migrations")
    end
  end
end

def verifyDatabasesAndTablesExist

  _verifyDBExists

  openConnectionIfNotOpen
  
  $dbConnection.exec(<<~END
    CREATE TABLE IF NOT EXISTS config (key TEXT UNIQUE PRIMARY KEY,
      value TEXT DEFAULT NULL)
    END
                    )

  # Main table for data
  $dbConnection.exec(<<~END
    CREATE TABLE IF NOT EXISTS seenposts (id TEXT UNIQUE PRIMARY KEY,
      sent BOOLEAN DEFAULT 'false', url TEXT DEFAULT NULL)
    END
                    )  
  
  # Check version
  _verifyTableVersions
  
end

def checkHasPostBeenSent(id)

  result = $dbConnection.exec_params("SELECT 1 FROM seenposts WHERE id = $1;", [id])
  return result.ntuples == 1
end

def setPostAsSent(id, url = nil)
  $dbConnection.exec_params("INSERT INTO seenposts (id, sent, url) VALUES ($1, true, $2);",
                            [id, url])
end






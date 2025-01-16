#!/usr/bin/env rackup

# frozen_string_literal: true

require 'dotenv'

Dotenv.load

require_relative '../lib/robin-cms'

run RobinCMS::CMS

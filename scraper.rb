#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require_relative 'lib/unspan_all_tables'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links
  decorator UnspanAllTables

  field :members do
    member_items.map { |tr| fragment(tr => MemberItem).to_h }
  end

  private

  def member_items
    noko.xpath('//table[.//th[contains(.,"MHKs")]]//tr[td]')
  end
end

class MemberItem < Scraped::HTML
  field :name do
    name_parts.first
  end

  field :identifier__wikidata do
    tds[1].css('a').first&.attr('wikidata')
  end

  field :party do
    liberal? ? 'Liberal Vannin' : 'Independent'
  end

  field :party_id do
    liberal? ? 'Q6540820' : 'Q327591'
  end

  field :constituency do
    tds[0].text.tidy
  end

  field :constituency_id do
    tds[0].css('a/@wikidata').text
  end

  private

  def tds
    noko.css('td')
  end

  def name_parts
    tds[1].text.split(/[\(\)]/).map(&:tidy)
  end

  def liberal?
    name_parts[1] == 'Liberal Vannin'
  end
end

url = 'https://en.wikipedia.org/wiki/House_of_Keys'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name constituency])

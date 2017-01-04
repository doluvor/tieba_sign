#!/usr/bin/ruby
#encoding: UTF-8

require "net/http"
require "uri"
require "json"
require "cgi"
require "nokogiri"
require 'open-uri'
require 'digest/md5'

BDUSS = ""

def get_fid(kw)

	encoded_kw = URI::encode(kw.force_encoding('ASCII-8BIT'))

	uri = URI.parse('http://tieba.baidu.com/f/commit/share/fnameShareApi?ie=utf-8&fname=' + encoded_kw)
	response = Net::HTTP.get_response(uri)	
	return JSON.parse(response.body)['data']['fid']
end

def request(url, bduss)

	uri = URI.parse(url)	
	request = Net::HTTP::Get.new(uri.request_uri)
	http = Net::HTTP.new(uri.host, 80)
	
	if BDUSS	
		request["Cookie"] = "BDUSS=" + BDUSS
	end
	
	response = http.request(request)
	
	case response
	when Net::HTTPSuccess then response
	when Net::HTTPRedirection then response = request(response["location"], BDUSS)
	else
	end
end

def get_tbs
	response = request('http://tieba.baidu.com/dc/common/tbs', BDUSS)
	return JSON.parse(response.body)['tbs']
end

def get_favorite
	response = request('http://tieba.baidu.com/f/like/mylike?&pn=', BDUSS)
		
	doc = Nokogiri::XML(response.body, nil, 'UTF-8')
	
	tds = doc.css("div.forum_table table tr").select do |forum|

		forum.css("td").first != nil
	end
	
	forum = tds.map do |forum|
		
		forum.css("td").first.css("a").text
		
	end
	
	return forum
end

def sign(fid, kw, tbs, bduss)

	url='http://c.tieba.baidu.com/c/c/forum/sign'

	data = {"fid" => fid,
			"kw" => kw,
			"tbs" => tbs,
			"BDUSS" => bduss}

	sorted_data = data.sort.to_h

	s = ""

	sorted_data.each do | key, value |
		s += key.to_s + "=" + value.to_s
	end

	s += "tiebaclient!!!"

	md5 = Digest::MD5.hexdigest(s).upcase

	data["sign"] = md5

	uri = URI.parse(url)

	http = Net::HTTP.new(uri.host, 80)
	request = Net::HTTP::Post.new(uri.request_uri)
	request.set_form_data(data)
	response = http.request(request)

	print(response.body)
end

forums = get_favorite
tbs = get_tbs

forums.each do |forum|
	fid = get_fid(forum)
	sign(fid, forum, tbs, BDUSS)
end

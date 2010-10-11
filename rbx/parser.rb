require 'rubygems'
require 'citrus'

base = File.dirname(__FILE__) + "/parser/"
require base+"nodes"
Citrus.load base + "fancy.citrus"


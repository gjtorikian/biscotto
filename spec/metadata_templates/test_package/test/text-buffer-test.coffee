{join} = require 'path'
temp = require 'temp'
{File} = require 'pathwatcher'
TextBuffer = require '../src/text-buffer'
SampleText = readFileSync(join(__dirname, 'fixtures', 'sample.js'), 'utf8')

describe "TextBuffer", ->
  buffer = null

  afterEach ->
    buffer = null

module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-release'

  grunt.initConfig
    release:
      options:
        bump: false
        add: false
        push: false
        tagName: "v<%= version %>"
    exec:
      test:
        command: "./node_modules/jasmine-node/bin/jasmine-node --coffee spec"

  grunt.loadNpmTasks('grunt-exec')

  grunt.registerTask('test', 'exec:test')

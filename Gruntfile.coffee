module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-exec'
  grunt.loadNpmTasks 'grunt-gh-pages'

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
      build_docs:
        command: "./bin/biscotto src/"

    'gh-pages':
      options:
        base: "doc"
      src: ['**']

  grunt.registerTask('test', 'exec:test')
  grunt.registerTask('publish', ['exec:build_docs', 'gh-pages'])

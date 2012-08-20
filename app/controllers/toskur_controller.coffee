Chaplin = require 'chaplin'
Garbage = require 'core/garbage'
Store = require 'models/store'
SidebarRootFolderView = require 'views/sidebar_root_folder'
BreadcrumbView = require 'views/breadcrumb'
MainFolderView = require 'views/main_folder'
MainListView = require 'views/main_list'
MainFilteredListView = require 'views/main_filtered_list'

# The main controller of the lists app.
module.exports = class TöskurController extends Chaplin.Controller

    historyURL: (params) -> ''

    # Here be `Store`.
    store: undefined

    initialize: ->
        # Storage for objects to be garbage collected.
        @views = new Garbage()

        # Give us the Store, inject the API fetched data.
        @store = new Store window.App.data.lists

        # Render the root folder (and onwards) in the sidebar.
        @views.push 'lists', new SidebarRootFolderView 'model': @store.findFolder('/')

        # Receive filter list messages.
        Chaplin.mediator.subscribe 'filterLists', @filterLists

    # Need to dispose of us listening to `filterLists`.
    dispose: ->
        for channel in [ 'filterLists' ]
            Chaplin.mediator.unsubscribe channel

        super

    ###
    The user wants to filter the lists.
    @param {string} filter
    ###
    filterLists: (filter) =>
        # Remove existing filtered list.
        @views.disposeOf 'filter'

        # Is this a 'clearing' query?
        if filter is ''
            # Show the original...
            @views.objects?.main.render()
        else
            # Filter the collection.
            re = new RegExp "#{filter}.*", 'i'
            coll = new Chaplin.Collection @store.filter (list) -> list.get('name').match re

            # Show the filtered lists.
            @views.push 'filter', new MainFilteredListView 'collection': coll

    ### 
    Show the default index page.
    @param {Object} params Passed in properties
    ###
    index: (params) ->
        # Main view, show the root folder.
        @views.push 'main', new MainFolderView 'model': folder = @store.findFolder('/')

        # Say that we selected this folder.
        Chaplin.mediator.publish 'activeFolder', folder

    ###
    Show an individual list by its `slug`.
    @param {Object} params Passed in properties
    ###
    list: (params) ->
        # Retrieve the list in question.
        list = @store.findList params.slug
        unless list?
            Chaplin.mediator.publish 'notification', 'This list has not been found'
        else
            Chaplin.mediator.publish 'notification', 'You have asked for this list', list.get('name')

            # We have the list, so expand the path towards the list.
            @store.expandFolder list.get 'path'

            # Main view, show the selected list and its contents.
            @views.push 'main', new MainListView 'collection': list.get 'objects'

            # Create a breadcrumb View for this list.
            @views.push new BreadcrumbView 'collection': @store.getPath list

    ###
    Show an individual folder by its `slug`.
    @param {Object} params Passed in properties
    ###
    folder: (params) ->
        if params.length isnt 1
            # Do it the good way and merge all the `s*` key values together.
            slug = []
            for i in [0...20]
                if params[key = "s#{i}"]? then slug.push params[key]
                else break
            folder = @store.folders.where('slug': slug.join('/'))?[0]
        else
            folder = @store.folders.where('slug': params.slug)?[0]

        # Did we find the folder?
        unless folder?
            Chaplin.mediator.publish 'notification', 'This folder has not been found'
        else
            Chaplin.mediator.publish 'notification', 'You have asked for this folder', folder.get('name')

            # Set this folder as active.
            @store.activeFolder folder

            # We have the folder, so expand the path towards the folder.
            @store.expandFolder folder

            # Main view, show the selected folder.
            @views.push 'main', new MainFolderView 'model': folder

            # Create a breadcrumb View for this folder.
            @views.push new BreadcrumbView 'collection': @store.getPath folder

            # Say that we selected this folder.
            Chaplin.mediator.publish 'activeFolder', folder
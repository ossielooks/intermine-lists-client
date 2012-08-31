Chaplin = require 'chaplin'

Mediator = require 'chaplin/core/Mediator'
Garbage = require 'chaplin/core/Garbage'

# The Views.
LayoutView = require 'chaplin/views/page/Layout'
SidebarFolderHolderView = require 'chaplin/views/tree/SidebarFolderHolder'
BreadcrumbView = require 'chaplin/views/head/Breadcrumb'
FolderHolderView = require 'chaplin/views/main/FolderHolder'
ListObjectHolderView = require 'chaplin/views/main/ListObjectHolder'
FilteredListHolderView = require 'chaplin/views/main/FilteredListHolder'

# The main controller of the lists app.
module.exports = class TöskurController extends Chaplin.Controller

    historyURL: (params) -> ''

    # Link to main Store.
    store: null

    initialize: ->
        # Storage for objects to be garbage collected.
        @views = new Garbage()
        @views.push new LayoutView()

        # Main Store.
        @store = window.Store

        # Make sure that no lists are selected.
        Mediator.publish 'deselectAll'

        # Receive filter list messages.
        Mediator.subscribe 'filterLists', @filterLists, @

    # Need to dispose of us listening to `filterLists`.
    dispose: ->
        super

        # Clear the filterLists channel only. If we reset the whole Mediator, Store will be left out (Bug 139).
        Mediator.unsubscribe 'filterLists', null, @
        # But at the same time unsubscribe all from `notification` messages.
        Mediator.unsubscribe 'notification', null, null

    ###
    The user wants to filter the lists.
    @param {string} filter
    ###
    filterLists: (filter) ->
        # Trigger a message saying that all Views should deselect their... selections.
        Mediator.publish 'deselectAll'

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
            @views.push 'filter', new FilteredListHolderView 'collection': coll

    ### 
    Show the default index page.
    @param {Object} params Passed in properties
    ###
    index: (params) ->
        # Get the root folder.
        root = @store.findFolder('/')

        # Set this folder as active.
        @store.activeFolder root

        # Render the root folder (and onwards) in the sidebar.
        @views.push 'lists', new SidebarFolderHolderView 'model': root

        # Main view, show the root folder.
        @views.push 'main', new FolderHolderView 'model': root

        # Say that we selected this folder.
        Mediator.publish 'activeFolder', root

    ###
    Show an individual list by its `slug`.
    @param {Object} params Passed in properties
    ###
    list: (params) ->
        # Render the root folder (and onwards) in the sidebar.
        @views.push 'lists', new SidebarFolderHolderView 'model': @store.findFolder('/')

        # Retrieve the list in question.
        list = @store.findList params.slug
        unless list?
            Mediator.publish 'notification', 'This list has not been found'
        else
            Mediator.publish 'notification', 'You have asked for this list', list.get('name')

            # We have the list, so expand the path towards the list.
            @store.expandFolder list.get 'path'

            # Main view, show the selected list and its contents.
            @views.push 'main', new ListObjectHolderView 'collection': list.get 'objects'

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
            Mediator.publish 'notification', 'This folder has not been found'
        else
            Mediator.publish 'notification', 'You have asked for this folder', folder.get('name')

            # Set this folder as active.
            @store.activeFolder folder

            # We have the folder, so expand the path towards the folder.
            @store.expandFolder folder

            # Main view, show the selected folder.
            @views.push 'main', new FolderHolderView 'model': folder

            # Create a breadcrumb View for this folder.
            @views.push new BreadcrumbView 'collection': @store.getPath folder

            # Say that we selected this folder.
            Mediator.publish 'activeFolder', folder

        # Render the root folder (and onwards) in the sidebar.
        @views.push 'lists', new SidebarFolderHolderView 'model': @store.findFolder('/')
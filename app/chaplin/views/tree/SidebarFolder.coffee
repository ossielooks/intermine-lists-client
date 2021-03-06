Mediator = require 'chaplin/core/Mediator'
Garbage = require 'chaplin/core/Garbage'
View = require 'chaplin/core/View'

module.exports = class SidebarFolderView extends View

    tagName: 'li' # a list item

    toggleEl: undefined # points to the toggler element

    # Get the template from here.
    getTemplateFunction: -> require 'chaplin/templates/sidebar_folder'

    # 'Serialize' our opts and add cid so we can constrain events.
    getTemplateData: -> _.extend { 'cid': @model.cid }, @model.toJSON()

    initialize: ->
        super

        # The garbage truck... wroom!
        @views = new Garbage()

    # Render the subviews.
    afterRender: ->
        super

        # Dispose of previous subviews and clean up events.
        @undelegate()
        @views.dump()

        # Events only on this folder.
        @delegate 'click', ".folder.#{@model.cid}.toggle", @toggleFolder
        @modelBind 'change', @render

        # Are we set as active?
        if @model.get('active') then $(@el).addClass('active')

        # Make the folder droppable.
        $(@el).find('.drop:not(.ui-droppable)').droppable
            'over': @over
            'out':  @out
            'drop': @drop

        # Make a link to toggle element.
        @toggleEl = $(@el).find('.toggle')

        # Render the subviews.
        if @model.get('path') is '/' or @model.get('expanded')
            # Render our folders.
            for folder in @model.get 'folders'
                $(@el).find('ul.folders').first().append (v = new SidebarFolderView('model': folder)).render().el
                @views.push v

        # If we have folders then show a toggler for this folder.
        if @model.get('folders').length isnt 0
            $(@el).find(".folder.#{@model.cid}.toggle").addClass do =>
                if @model.get 'expanded' then 'active icon-caret-down'
                else 'active icon-caret-right'

    # Toggle the folder, the view is listening to Model changes already.
    toggleFolder: -> @model.set 'expanded', !@model.get('expanded')

    over: (e) =>
        $(e.target).addClass 'hover'
        @toggleEl.addClass 'hover'

    out: (e) =>
        $(e.target).removeClass 'hover'
        @toggleEl.removeClass 'hover'

    # A dragged list has been dropped on us.
    drop: (e, ui) =>
        assert @model?, "Folder Model is not attached"

        # Remove the hover sign.
        $(e.target).removeClass 'hover'
        @toggleEl.removeClass 'hover'
        
        # Get the data associated.
        lists = $(ui.draggable).data('collection')

        # The new path.
        newPath = @model.get('path')

        # Update all the lists that were passed in.
        lists.each (list) =>
            # The old path.
            oldPath = list.get('path')

            # Are the paths the same?
            if newPath isnt oldPath
                # Message about it.
                Mediator.publish 'notification', "Has been moved from \"#{oldPath}\" to \"#{newPath}\"", list.get('name')

                # Update the list path itself.
                list.set 'path', newPath

                # Push the list on this folder.
                @model.addList list

        # Deselect all lists.
        Mediator.publish 'deselectAll'

        # Tell the main View to update itself.
        Mediator.publish 'renderMain'
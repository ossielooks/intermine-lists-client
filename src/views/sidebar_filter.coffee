define [
    'chaplin'
    'core/view'
], (Chaplin, View) ->

    class SidebarFilterView extends View

        container:  '#filtering'
        autoRender: true

        # Save the filter timeout here.
        timeout: null

        # The 'current' filter query.
        query: null

        getTemplateFunction: -> JST['filtering']

        afterRender: ->
            super

            @delegate 'keyup', 'input', @filter

        # Extend dispose by getting rid of internal timeout.
        dispose: ->
            if @timeout? then clearTimeout @timeout
            delete @timeout

            super

        filter: (e) ->
            # Delay any further processing by a few.
            if @timeout? then clearTimeout @timeout

            @timeout = setTimeout (=>
                # Fetch the query value.
                query = $(e.target).val()
                if query isnt '' and query isnt @query
                    # Trigger a message to other components to do their bidding.
                    Chaplin.mediator.publish 'filterLists', @query = query
            ), 500
React           = require("react")
converterModule = require("./converters")
invalidModule   = require('./Invalid')


get = invalidModule.get
set = invalidModule.set

# TODO/Extra
    # add some props
        # required, invalidClass, validateImmediately(show red on empty required fields onload), validateOnblur (show red only after/not during field editing)
    # add more converters
        # numeric, integer, decimal, percent
        
# EVENTUALLY
    # add masking, mask=[/[^@]+/,"@",/\d/,"."]



# re-exports
converters = converterModule.converters ; module.exports.converters = converters
Invalid    = invalidModule.Invalid      ; module.exports.Invalid    = Invalid
isInvalid  = invalidModule.isInvalid    ; module.exports.isInvalid  = isInvalid



# helper function
resetCursor = (thisFromInput) ->
        if get(thisFromInput, ["refs", "input", "selectionStart"], "")
            inputSelectionStart = thisFromInput.refs.input.selectionStart
            
        
        moveCursor = () ->
            cursorPos = get(thisFromInput, ["refs", "input", "selectionStart"], "")
            if cursorPos
                if inputSelectionStart
                    thisFromInput.refs.input.selectionStart = inputSelectionStart
                    thisFromInput.refs.input.selectionEnd   = inputSelectionStart
        
        setTimeout( moveCursor, 0)


class Input extends React.Component
    
    constructor: (props) ->
        super(props)
        this.hasCompletedTheInitialFilter = false
    
    render: ->
        props = this.props
        
        # extract values from props
        expectedProps = []
        expectedProps.push("invalidStyle"   ); if props.invalidStyle   then invalidStyle   = props.invalidStyle   else invalidStyle   = null
        expectedProps.push("linkTo"         ); if props.linkTo         then linkTo         = props.linkTo         else linkTo         = null
        expectedProps.push("className"      ); if props.className      then className      = props.className      else className      = "easy-input"
        expectedProps.push("classAdd"       ); if props.classAdd       then classAdd       = props.classAdd       else classAdd       = ""
        expectedProps.push("incomingFilter" ); if props.incomingFilter then incomingFilter = props.incomingFilter else incomingFilter = null
        expectedProps.push("outgoingFilter" ); if props.outgoingFilter then outgoingFilter = props.outgoingFilter else outgoingFilter = null
        expectedProps.push("value"          ); if props.value          then value          = props.value          else value          = null
        # create a mutable version of props
        newProps = {}
        for each in Object.keys(props)
            if not expectedProps.includes(each)
                newProps[each] = props[each]
        
        
        #
        # retrieve converters
        #
        if converters[newProps.type] then converter = converters[newProps.type] else converter = {}
        if not outgoingFilter then outgoingFilter = converter.outgoingFilter
        if not incomingFilter then incomingFilter = converter.incomingFilter
        # FIXME, wrap the incomingFilter to make sure it always receives non-Invalid() values
        
        #
        # calculate value
        #
        if newProps.this and linkTo
            # retrieve the actual value from the component's state
            newProps.value = get(newProps.this.state, linkTo, "")
        
        # Check the initial value
        if incomingFilter and !this.hasCompletedTheInitialFilter
            initialValue = newProps.value
            newProps.value = incomingFilter(newProps.value)
            this.hasCompletedTheInitialFilter = true
            if initialValue != newProps.value
                # if the initial value is different, call the onchange
                if newProps.onChange
                    newProps.onChange({target:{value:newProps.value}})
        
        # preserve the validity/un-validityness
        valueIsInvalid = isInvalid newProps.value #FIXME, there could be a better solution than this
        
        # always run outgoing filters
        if outgoingFilter then newProps.value = outgoingFilter(newProps.value)
        # always convert null values to "" (otherwise react will complain)
        if newProps.value is null or newProps.value is undefined then newProps.value = ""
        if valueIsInvalid then newProps.value = new Invalid(newProps.value)
        
        
        #
        #   Compute onChange
        #
        if not newProps.onChange
            # first reset the cursor, then handle the change
            newProps.onChange  = (e) =>
                newValue = e.target.value
                resetCursor(this)
                
                # if there is a converter function, then run the function before it returns to state
                # for example convert "True" into the boolean: true,
                # or convert the string "Jan 12 2017" to dateTime(1,12,2017)
                if incomingFilter
                    newValue = incomingFilter(newValue)
                
                # create a copy of state instead of mutating the original
                copyOfState = Object.assign(newProps.this.state)
                invalidModule.set(copyOfState, linkTo, newValue)
                props.this.setState(copyOfState)
                
        else
            newProps.onChange  = (e) =>
                e.persist() # react will destroy e if we don't tell it to persist
                newValue = e.target.value
                resetCursor(this)
                # if there is a converter function, then run the function before it returns to state
                # for example convert "True" into the boolean: true,
                # or convert the string "Jan 12 2017" to dateTime(1,12,2017)
                if incomingFilter
                    newValue = incomingFilter(newValue)
                
                props.onChange({target:{value:newValue}})
                
        
        
        

        #
        # Calculate styling/css class
        #
        # add additional classes
        newProps.className = className + " " + classAdd
        displayInvalid = no
        # if 'invalid' prop was set to something (true/false)
        if typeof newProps.invalid == 'bool'
            # and if 'invalid' is true
            if newProps.invalid is true
                # then display it
                displayInvalid = yes
            # if 'invalid' is false, dont add error class
        # if 'invalid' prop was not set, but the state value is indeed invalid, then displayInvalid
        else if isInvalid newProps.value
            # then display it
            displayInvalid = yes
        
        if displayInvalid is yes
            # add the error css class
            className = "easy-input-error " + className
            # check if there is an invalid style
            if invalidStyle
                # if there is one then attach it
                newProps.style = invalidStyle
        
        # set a reference for fixing the cursor jump
        newProps.ref = "input"
        
        # return the react input component
        return React.createElement('input', newProps, null)
        
    
module.exports.Input = Input



# validate onblur instructions (implement in next few versions)
    # onChange={
    #     (e)=>{
    #         var val = e.target.value
    #         e.persist()
    #         setTimeout(() => {
    #             e.target.onblur = () => {
    #                 console.log(`val is:`,val)
    #                 var matches = val.match(/^.+@.+\..+$/)
    #                 console.log(`val.match(/\\d+/) is:`,val.match(/\d+/))
    #                 if (!matches) {
    #                     console.log(`doesnt match`)
    #                     e.target.setCustomValidity("Needs to be a number")
    #                     e.target.classList.add('input-err')
    #                     // this.refs.form.reportValidity()
    #                 } else {
    #                     console.log(`matches`)
                        
    #                 }
    #             }
    #         }, 0);
    #         this.setState({Nums:val})
    #     }
    # }
    # />
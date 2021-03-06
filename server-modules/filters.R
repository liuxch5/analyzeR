applyFilters <- function(alert, dateformat, input, output, session, vals) {
  tryCatch({
    df <- vals$datadf
    
    # Complete Cases Filters
    if(vals$completeCasesFilterCount > 0) {
      for(filter in 1:vals$completeCasesFilterCount){
        filterCols <- input[[paste0("completeCasesFilter",filter)]]
        
        df <- df[complete.cases(df[, filterCols]), ]
      }
    }
    
    # Value Filters
    if(vals$valueFilterCount > 0) {
      for(filter in 1:vals$valueFilterCount){
        filterCol <- input[[paste0("valueFilter",filter)]]
        filterMin <- input[[paste0("valueFilter",filter, "Min")]]
        filterMax <- input[[paste0("valueFilter",filter, "Max")]]
        
        filterMin <- as.numeric(filterMin)
        filterMax <- as.numeric(filterMax)
        df[, filterCol] <- as.numeric(df[, filterCol])
        
        if(is.na(filterMax)) filterMax <- Inf
        if(is.na(filterMin)) filterMin <- -Inf
        
        df <- subset(df, (df[,filterCol] <= filterMax & df[,filterCol] >= filterMin) | is.na(df[,filterCol]))
      }
    }
    
    # Percentile Filters
    if(vals$percentileFilterCount > 0) {
      for(filter in 1:vals$percentileFilterCount){
        filterCol <- input[[paste0("percentileFilter",filter)]]
        filterMin <- input[[paste0("percentileFilterSlider",filter)]][1]
        filterMax <- input[[paste0("percentileFilterSlider",filter)]][2]
        
        df[, filterCol] <- as.numeric(df[, filterCol])
        
        filterMin <- as.numeric(filterMin)
        filterMax <- as.numeric(filterMax)
        
        if(is.na(filterMax)) filterMax <- 1
        if(is.na(filterMin)) filterMin <- 0
        
        filterMax <- quantile(df[, filterCol], filterMax, na.rm = TRUE)
        filterMin <- quantile(df[, filterCol], filterMin, na.rm = TRUE)
        
        df <- subset(df, (df[,filterCol] <= filterMax & df[,filterCol] >= filterMin) | is.na(df[,filterCol]))
      }
    }
    
    # Date Filters
    if(vals$dateFilterCount > 0) {
      for(filter in 1:vals$dateFilterCount){
        filterCol <- input[[paste0("dateFilter",filter)]]
        filterMin <- input[[paste0("dateFilter",filter, "Min")]]
        filterMax <- input[[paste0("dateFilter",filter, "Max")]]
        
        if(dateformat) {
          updateTextInput(session, paste0("dateFilter",filter,"Format"), value = input$dateAggDateColFormat)
          filterDateFormat <- input$dateAggDateColFormat
        } else {
          filterDateFormat <- input[[paste0("dateFilter",filter,"Format")]]
        }
        
        filterMin <- as.Date(filterMin, format= filterDateFormat)
        filterMax <- as.Date(filterMax, format= filterDateFormat)
        
        if(is.na(filterMax)) filterMax <- Inf
        if(is.na(filterMin)) filterMin <- -Inf
        
        df[,filterCol] <- as.Date(as.character(df[,filterCol]), format= filterDateFormat)
        if(!vals$validateDates(df[,filterCol])) return(NULL)
        df <- subset(df, (df[,filterCol] <= filterMax & df[,filterCol] >= filterMin) | is.na(df[,filterCol]))
        df <- df[order(df[,filterCol]), ]
        df[, filterCol] <- as.character(format(df[, filterCol], filterDateFormat))
      }
    }
    
    # String Filter
    if(vals$stringFilterCount > 0) {
      for(filter in 1:vals$stringFilterCount){
        filterCol <- input[[paste0("stringFilter",filter)]]
        filterstring  <- input[[paste0("string",filter)]]
        df <- subset(df, (df[,filterCol] == filterstring))
      }
    }
    
    vals$datadf <- df
  
    if(alert) {
      shinyalert(
        title = "",
        text = "Your data has been filtered according to your specifications. You can find the updated dataset in the 'Data Preview' tab.",
        closeOnEsc = TRUE,
        closeOnClickOutside = TRUE,
        html = FALSE,
        type = "success",
        showConfirmButton = TRUE,
        showCancelButton = FALSE,
        confirmButtonText = "OK",
        confirmButtonCol = "#3E3F3A",
        timer = 0,
        imageUrl = "",
        animation = TRUE
      )
    }
  },error=function(e) {
      if(DEBUG_MODE) {
        stop(e)
      }
      shinyerror(e)
  })
}

observeAddFilter <- function(input, output, session, vals) {
  
  observeEvent(input$addFilter, {
    filter <- input$filterSelected
    filterName <- names(filterList[filterList==filter])
    
    switch(filter,
           completeCasesFilter = {
             vals$completeCasesFilterCount <- vals$completeCasesFilterCount + 1
             cnt <- vals$completeCasesFilterCount
             insertUI(selector="#filters",
                      where="afterBegin",
                      ui = tags$div(h3(filterName),
                                    tags$div(textInput(paste0("filterType", cnt), label = NULL, value=filter),style="display:none;"),
                                    selectInput(paste0("completeCasesFilter", cnt), "Select Columns; rows with NAs will be removed", choices=vals$getCols(), multiple = TRUE),
                                    tags$div(tags$hr()), class="valueFilter"))
           },
           valueFilter = {
             vals$valueFilterCount <- vals$valueFilterCount + 1
             cnt <- vals$valueFilterCount
             insertUI(selector="#filters",
                      where="afterBegin",
                      ui = tags$div(h3(filterName),
                                    tags$div(textInput(paste0("filterType", cnt), label = NULL, value=filter),style="display:none;"),
                                    selectInput(paste0("valueFilter", cnt), "Column", vals$getCols()),
                                    tags$div(textInput(paste0("valueFilter", cnt, "Min"), "Min"), style="display:inline-block"),
                                    tags$div(textInput(paste0("valueFilter", cnt, "Max"), "Max"), style="display:inline-block"),
                                    tags$div(tags$hr()), class="valueFilter"))
           },
           percentileFilter = {
             vals$percentileFilterCount <- vals$percentileFilterCount + 1
             cnt <- vals$percentileFilterCount
             insertUI(selector="#filters",
                      where="afterBegin",
                      ui = tags$div(h3(filterName),
                                    tags$div(textInput(paste0("filterType", cnt), label = NULL, value=filter),style="display:none;"),
                                    selectInput(paste0("percentileFilter", cnt), "Column", vals$getCols()),
                                    sliderInput(paste0("percentileFilterSlider", cnt), NULL, min=0, max=1, value=c(0,1), step=0.01),
                                    tags$div(tags$hr()), class="percentileFilter"))
           },
           dateFilter = {
             vals$dateFilterCount <- vals$dateFilterCount + 1
             cnt <- vals$dateFilterCount
             insertUI(selector="#filters",
                      where="afterBegin",
                      ui = tags$div(h3(filterName),
                                    selectInput(paste0("dateFilter", cnt), "Column", vals$getCols()),
                                    tags$div(
                                      tags$div(textInput(paste0("dateFilter", cnt, "Min"), "Min"), style="display:inline-block"),
                                      tags$div(textInput(paste0("dateFilter", cnt, "Max"), "Max"), style="display:inline-block")
                                    ),
                                    tags$div(
                                      tags$div(textInput(paste0("dateFilter", cnt, "Format"), "Format dates are in (check 'Data Preview' tab)", "%m/%d/%Y"), style="display:inline-block"),
                                      tags$div(a("Example Formats", href="http://www.statmethods.net/input/dates.html", target="_blank"), style="display:inline-block")
                                    ),
                                    tags$div(tags$hr(), class="dateFilter"), class="dateFilter"))
           },
           strFilter = {
             vals$stringFilterCount <- vals$stringFilterCount + 1
             cnt <- vals$stringFilterCount
             insertUI(selector="#filters",
                      where="afterBegin",
                      ui = tags$div(h3(filterName),
                                    tags$div(textInput(paste0("filterType", cnt), label = NULL, value=filter),style="display:none;"),
                                    selectInput(paste0("stringFilter", cnt), "Column", vals$getCols()),
                                    tags$div(textInput(paste0("string", cnt), "String (only rows with these values will be kept)"), style="display:inline-block"),
                                    tags$div(tags$hr()), class="stringFilter"))
           }
        )
    
  })
  
}

observeApplyFilters <- function(input, output, session, vals) {
  
  # Apply Filters Button
  observeEvent(input$applyFilters, {
    applyFilters(TRUE, FALSE, input, output, session, vals)
  })

}

observeClearFilters <- function(input, output, session, vals) {
  
  # Clear Filters Button
  observeEvent(input$filterClear, {
    
    if(!input$filterClear && !input$aggClear){
      return(NULL)
    }
    
    removeUI(".valueFilter", multiple = TRUE)
    removeUI(".percentileFilter", multiple = TRUE)
    removeUI(".dateFilter", multiple = TRUE)
    removeUI(".stringFilter", multiple = TRUE)
    vals$valueFilterCount <- 0
    vals$percentileFilterCount <- 0
    vals$dateFilterCount <- 0
    vals$stringFilterCount <- 0
    vals$datadf <- vals$originaldf

    shinyalert(
      title = "",
      text = "Your filter(s) have been removed. Any date aggregation or metric transformations you've created will be re-created in the following order: First the data will be aggregated by date, then transformations wil be re-made.",
      closeOnEsc = TRUE,
      closeOnClickOutside = TRUE,
      html = FALSE,
      type = "success",
      showConfirmButton = TRUE,
      showCancelButton = FALSE,
      confirmButtonText = "OK",
      confirmButtonCol = "#3E3F3A",
      timer = 0,
      imageUrl = "",
      animation = TRUE
    )
    
    if(vals$IsAggregated) aggregateData(input, output, session, vals)
    
  })
  
}

###########################
# Option Panel Conditions #
###########################
loadConditions <- function(input, output, session, vals) {
  
  output$binaryYCheck <- reactive({
  
    if(input$yCol == "") return(NULL)
    
    if(is.null(vals$metricdivedf)) return(NULL)
    if(nrow(vals$metricdivedf)==0) return(NULL)
    
    yvals <- vals$metricdivedf[, input$yCol]
    yvals <- yvals[!is.na(yvals)]
    return(length(unique(yvals)) == 2)
  })
  outputOptions(output, 'binaryYCheck', suspendWhenHidden=FALSE)
  
  output$aggCheck <- reactive({
    return(vals$IsAggregated)
  })
  outputOptions(output, 'aggCheck', suspendWhenHidden=FALSE)
  
	output$fileUploaded <- reactive({
	  return(nrow(vals$originaldf) > 0)
	})
	outputOptions(output, 'fileUploaded', suspendWhenHidden=FALSE)

	output$transformationsCheck <- reactive({
	  return(vals$transformationCount > 0)
	})
	outputOptions(output, 'transformationsCheck', suspendWhenHidden=FALSE)  

	output$filtersCheck <- reactive({
	  return(vals$valueFilterCount > 0 || vals$percentileFilterCount > 0 || vals$dateFilterCount > 0 || vals$completeCasesFilterCount > 0 ||vals$stringFilterCount > 0 )
	})
	outputOptions(output, 'filtersCheck', suspendWhenHidden=FALSE)

	output$offsetsCheck <- reactive({
	  return(vals$offsetCount > 0)
	})
	outputOptions(output, 'offsetsCheck', suspendWhenHidden=FALSE)

	output$validX <- reactive({
	  return(TRUE)
  	if(input$xCol != "" && input$yCol != "") {
  	  df <- vals$datadf
  	  
  	  if(!input$xCol %in% names(df)) { return(FALSE) }
  	  
  	  df <- subset(df, !is.na(df[,input$xCol]) & !is.na(df[,input$yCol]))

  	  return(sum(!is.na(as.numeric(df[, input$xCol]))) != 0)
  	}
	})
	outputOptions(output, 'validX', suspendWhenHidden=FALSE)

	output$pageFilterCheck <- reactive({
	  return(input$pageFilterCheck)
	})
	outputOptions(output, 'pageFilterCheck', suspendWhenHidden=FALSE)

	output$dateColCheck <- reactive({
	  return(input$dateCol != "")
	})
	outputOptions(output, 'dateColCheck', suspendWhenHidden=FALSE)

	output$catColCheck <- reactive({
	  return(input$categoryCol != "")
	})
	outputOptions(output, 'catColCheck', suspendWhenHidden=FALSE)

	output$dateColCheck <- reactive({
	  return(input$dateCol != "")
	})
	outputOptions(output, 'dateColCheck', suspendWhenHidden=FALSE)

	output$pointFilterCheck <- reactive({
	  return(input$pointFilterCheck)
	})
	outputOptions(output,'pointFilterCheck', suspendWhenHidden=FALSE)
	
	output$bigDataCheck <- reactive({
	  return(nrow(vals$metricdivedf) > MAX_ROW_LIMIT)
	})
	outputOptions(output,'bigDataCheck', suspendWhenHidden=FALSE)
	
}
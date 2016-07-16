library(shiny)
library(plyr)
library(igraph)
library(rCharts)
library(DT)
library(stringdist)

shinyServer(function(input, output)
{
  withProgress(message = "Processing Data", min = 0, max = 1, value = 0,
  {
    #Load all data into program
    incProgress(amount = 0.1, detail = "Loading CSV files")
    Interactions.csv <- read.csv("interactions.csv", header = F, sep = " ")
    Individuals.csv <- read.csv("individuals.csv", header = F, sep = " ")
                   
    #set a boolean flag for chart render
    firstRender <- TRUE
                   
    #Move graph information into data frames
    incProgress(amount = 0.1, detail = "Moving CSV files into data frame")
    Links <- data.frame(Interactions.csv)
    Nodes <- data.frame(Individuals.csv)
                   
    #rename headers for visNetwork
    incProgress(amount = 0.1, detail = "Renaming headers")
    colnames(Links) <- c("from","to","value")
    colnames(Nodes) <- c("id","title")
                   
    #Create igraph object, and get in/out/total degrees for each node
    incProgress(amount = 0.1, detail = "Calculating nodes degrees")
    G <- graph_from_data_frame(Links, directed = TRUE, vertices = Nodes)
    Nodes$inDegree <- degree(G, mode = c("in"))
    Nodes$outDegree <- degree(G, mode = c("out"))
                   
    #Filter out nodes of total degree 0
    incProgress(amount = 0.1, detail = "Filtering nodes")
    Nodes <- subset(Nodes, inDegree + outDegree > 0)
                   
    #caluclate centrality for each node
    incProgress(amount = 0.1, detail = "Calculating node centralities")
    G <- graph_from_data_frame(Links, directed = TRUE, vertices = Nodes)
    Nodes$value <- round(authority_score(G)$vector,3)
                   
    #calculate community membership for each node
    incProgress(amount = 0.2, detail = "Detecting communities")
    Communities.G <- walktrap.community(G)
    Nodes$group <- Communities.G$membership[1:(length(Communities.G$membership))]
    
    #calculate alias matrix
    Names <- ldply(strsplit(as.character(Individuals.csv$V2), split = "@"))[[1]]
  })
  
  output$mainGraph <- renderVisNetwork({
    withProgress(message = "Drawing graph", detail = "initialising visNetwork", min = 0, max = 1, value = 0,
    {
      #get first 2000 lines for faster processing
      Links <- Links[order(-Links$value),] 
      Links <- head(data.frame(Links),1000)

      #Subset by vertex degree
      incProgress(amount = 0.1, detail = "Subsetting by degree")
      Nodes <- subset(Nodes, inDegree >= input$inDegreeSlider[1] & inDegree <= input$inDegreeSlider[2])
      Nodes <- subset(Nodes, outDegree >= input$outDegreeSlider[1] & outDegree <= input$outDegreeSlider[2])
                     
      #Subset by vertex centrality
      incProgress(amount = 0.1, detail = "Subsetting by centrality")
      Nodes <- subset(Nodes, value >= input$centralitySlider[1] & value <= input$centralitySlider[2])    
                     
      #Subset by link weight
      incProgress(amount = 0.1, detail = "Subsetting by edge weight")
      Links <- subset(Links, value >= input$weightSlider[1] & value <= input$weightSlider[2])
                     
      #Subset by name
      incProgress(amount = 0.1, detail = "Subsetting by name")
      InputIds <- Nodes[grepl(input$verticiesSearchField,Nodes$title),]$id
      Links <- subset(Links, Links$from %in% InputIds | Links$to %in% InputIds)
      Nodes <- subset(Nodes, Nodes$id %in% Links$to | Nodes$id %in% Links$from)
      Links$title <- round(Links$value,2)
      
      #Subset by group
      if(!is.null(input$groupSelect))
      {
        Nodes <- subset(Nodes, Nodes$group %in% input$groupSelect)
      }

      if(nrow(Links) != 0)
      {
        hide("noGraphDataWarning")
        show("clickedNode")
        incProgress(amount = 0.3, detail = "rendering graph")
        visNetwork(Nodes, Links) %>%
        visPhysics(stabilization = list(iterations = 100, fit = TRUE), adaptiveTimestep = FALSE, solver = 'forceAtlas2Based', forceAtlas2Based = list(gravitationalConstant = -50, damping = 0.8, springConstant = 0.03)) %>%
        visEdges(smooth = FALSE, shadow = FALSE, value = TRUE, title = TRUE) %>% visNodes(font = list(size = 0), scaling = list(min = 10, max = 100)) %>%
        visEvents(deselectNode = "function(Nodes) {Shiny.onInputChange('currentNode', Nodes);}", selectNode = "function(Nodes) {Shiny.onInputChange('currentNode', Nodes);}") %>%
        visInteraction(tooltipDelay = 0, dragView = TRUE, hideEdgesOnDrag = TRUE, hoverConnectedEdges = TRUE) %>%
        visLayout(improvedLayout = FALSE) %>%
        visOptions(highlightNearest = TRUE, autoResize = FALSE)
      }
      else
      {
        show("noGraphDataWarning")
        hide("clickedNode")
      }
    })
  })
  
  output$clickedNode <- renderText({
    if(length(input$currentNode$nodes) != 0)
    {
      currentNode <- input$currentNode$nodes[[1]]
      paste(" ID: ", Nodes[currentNode+1,]$id+1,"\n","Name: ",Nodes[currentNode+1,]$title,"\n","Group: ",Nodes[currentNode+1,]$group)
    }
    else
    {
      paste("No individual selected, click on the graph to select a node! ")
    }
  })

  output$noGraphDataWarning <- renderText("No individuals meet the current search criteria, please refine the search parameters")
  
  output$noTableDataWarning <- renderText("The message rates for the selected users are zero, please refine the search parameters")
  
  output$individualsTableData <- DT::renderDataTable(server = FALSE, {
    withProgress(message = "Loading table", min = 0, max = 1, value = 0,
    {
      Nodes$id <- NULL
      Nodes$totalDegree <- NULL
      Nodes$group <- as.factor(Nodes$group)
      incProgress(amount = 1, detail = "Creating dataframe")
      colnames(Nodes) <- c("Name", "No. Recipients received from", "No. Recipients sent to", "Centrality", "Group")
      input$clearSelection
      Nodes
    })
  },options = list(pageLength = 20, processing = TRUE, searchDelay = 1500), filter = 'top', selection = 'none')
  
  output$individualsChart <- renderChart2({
    MessageDates.csv <- read.csv("messageDates.csv", header = F, sep = " ")
    MessageDates.csv$V3 <- match(MessageDates.csv$V3,month.abb)
    MessageDates.csv$V2 <- NULL
    MessageDates.csv$V6 <- NULL
    MessageDates.csv$V5 <- NULL
    MessageDates.csv$Date <- paste(MessageDates.csv$V4,MessageDates.csv$V3,MessageDates.csv$V7, sep = "/")
    MessageDates.csv$V3 <- NULL
    MessageDates.csv$V4 <- NULL
    MessageDates.csv$V7 <- NULL
    colnames(MessageDates.csv) <- c("id","Date")
    MessageDates.csv$id <- MessageDates.csv$id + 1
    
    MessageDates.csv$Date <- as.Date(MessageDates.csv$Date,format="%d/%m/%Y")
    selectedRows <- input$individualsTableData_rows_all
    
    if(is.null(selectedRows) | length(selectedRows) > 100)
    {
      hide("noTableDataWarning")
      if(!is.null(selectedRows))
      {
        MessageDates.csv <- MessageDates.csv[MessageDates.csv$id %in% selectedRows,]
      }
      MessageDates.csv$id <- NULL
      Chart <- count(MessageDates.csv)
      colnames(Chart) <- c("Date","Message_Rates_for_Filtered_Rows")
      Plot <- nPlot(Message_Rates_for_Filtered_Rows ~ Date, data = Chart, type = 'lineWithFocusChart')
      Plot$xAxis(axisLabel = "Date", tickFormat="#!function(d) {return d3.time.format('%d-%m-%Y')(new Date(d * 24 * 60 * 60 * 1000));}!#" )
      Plot$yAxis(axisLabel = "Frequency of Messages Sent", width = 40)
      Plot$chart(tooltipContent = "#! function(key, x, y){ return '<h3>' + key + '</h3>' + '<p>' + y + ' messages were sent on ' + x + '</p>'} !#")
      Plot
    }
    else
    {
      MessageDates.csv <- MessageDates.csv[MessageDates.csv$id %in% selectedRows,]
      
      if(nrow(MessageDates.csv) == 0)
      {
        show("noTableDataWarning")
      }
      else
      {
        hide("noTableDataWarning")
      }
      
      Chart <- count(MessageDates.csv)
      
      colnames(Chart) <- c("id","Date","messagesSent")
      Plot <- nPlot(messagesSent ~ Date, data = Chart, group = "id",  type = 'lineWithFocusChart')
      Plot$xAxis(axisLabel = "Date", tickFormat="#!function(d) {return d3.time.format('%d-%m-%Y')(new Date(d * 24 * 60 * 60 * 1000));}!#" )
      Plot$yAxis(axisLabel = "Frequency of Messages Sent", width = 40)
      Plot$chart(tooltipContent = "#! function(key, x, y){ return '<h3>' + key + '</h3>' + '<p>' + y + ' messages were sent on ' + x + '</p>'} !#")
      Plot
    }
  })
  
  output$aliasList <-  DT::renderDataTable({
    testName <- input$aliasesSearchField
    testName <- strsplit(testName, split = "@")[[1]][1]
    threshold <- 0.3
    if(testName %in% Names)
    {
      #get all names
      Names <- ldply(strsplit(as.character(Individuals.csv$V2), split = "@"))[[1]]
      #get all names containing dots
      NamesWithDots <- Names[grepl("[.]",Names)]
      #get all names not containing dots
      NamesWithoutDots <- subset(Names, !(Names %in% NamesWithDots))
      #add a dot to names that do not contain dots
      NamesWithoutDots <- paste(substr(NamesWithoutDots,1,1),".",substr(NamesWithoutDots,2,nchar(NamesWithoutDots)),sep = "")
      
      splitNamesA <-  strsplit(NamesWithoutDots, split = "[.]")
      splitNamesB <- strsplit(NamesWithDots, split = "[.]")
      
      x <- NULL
      y <- NULL
      
      for(i in 1:38)
      {
        x <- rbind(x,(splitNamesA[[i]][1]))
        y <- rbind(y,(splitNamesA[[i]][2]))
      }
      
      xy<-cbind(x,y)
      
      a <- NULL
      b <- NULL
      
      for(i in 1:3050)
      {
        a <- rbind(a,(splitNamesB[[i]][1]))
        b <- rbind(b,(splitNamesB[[i]][2]))
      }
      
      ab<-cbind(a,b)
      AllNames <- data.frame(rbind(xy,ab))
      colnames(AllNames) <- c("Fname","Lname")
      firstNames <- AllNames$Fname
      lastNames <- AllNames$Lname
      fullNames <- paste(firstNames, lastNames, sep = ".")
      
      splitTestName <- strsplit(testName, "[.]")
      testNameF <- splitTestName[[1]][1]
      testNameL <- splitTestName[[1]][2]
      fNameSimilarityMatrix <- stringdistmatrix(testNameF,firstNames,method = "jaccard")
      lNameSimilarityMatrix <- stringdistmatrix(testNameL,lastNames,method = "cosine")
      NameSimilarityMatrix <- (0.25*fNameSimilarityMatrix)+(0.75*lNameSimilarityMatrix)
      
      colnames(NameSimilarityMatrix) <- Names
      rownames(NameSimilarityMatrix) <- paste(testNameF,testNameL,sep = ".")

      FullNameList <- fullNames[unlist(NameSimilarityMatrix[testName,]< threshold)]
      data.frame(FullNameList)
    }
  })
  
  
  
})

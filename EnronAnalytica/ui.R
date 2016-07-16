library(shiny)
library(visNetwork)
library(DT)
library(rCharts)
library(shinyjs)
library(stringdist)

shinyUI(
    navbarPage(windowTitle = "Analytica",
    
      absolutePanel(img(src='logo.png', align = "left",height = "55px"),left = 29,top = -1),
      
      tabPanel(
        "Graph",
        useShinyjs(),
        sidebarPanel(
          width = "3",
          h4("Graph Options"),
          helpText("Graph nodes represent employees, whilst edges represent the email communication links between employees. "),
          selectInput("groupSelect",label = "Groups", choices = c(1:50), multiple = TRUE, selectize = TRUE),
          helpText("View specific groups in the graph by selecting from the drop down menu. The colours of nodes represent different groups"),
          textInput("verticiesSearchField", label = h5("Employee Search"), value = ""),
          helpText("Search for individual employees and quickly view their communication networks"),
          sliderInput("inDegreeSlider", label = h5("No. Recipients received from"), min = 0, max = 100, value = c(0, 100)),
          sliderInput("outDegreeSlider", label = h5("No. Recipients sent to"), min = 0, max = 400, value = c(0, 400)),
          helpText("Filter individuals by the number of unique individuals that an employee sent an email to / received an email from"),
          sliderInput("weightSlider", label = h5("No. messages exchanged"), min = 0, max = 1000, value = c(0, 1000)),
          helpText("Filter communication links by the messages exchanged. The thickness of the edge between two individuals corresponds to the amount of communication between them"),
          sliderInput("centralitySlider", label = h5("Employee Centrality"), min = 0, max = 1, value = c(0, 1)),
          helpText("Filters nodes by their calculated centrality score. The larger the size of a node, the greater the centrality of the individual")
        ),
        
        absolutePanel(top = 70, right = 50, verbatimTextOutput("clickedNode")),
        mainPanel(visNetworkOutput("mainGraph",width = 1600, height = 1000),absolutePanel(top = 450, right = 150, verbatimTextOutput("noGraphDataWarning")))

      ),

      tabPanel(
        "Individuals",
        column(6, actionButton("clearSelection","Reset filter"), br(), br(), DT::dataTableOutput('individualsTableData')),
        column(6,absolutePanel(top = 150, right = 100, verbatimTextOutput("noTableDataWarning")),
          showOutput("individualsChart","nvd3"), 
          br(), 
          wellPanel(h4("Help"), helpText("Use the table search bar and column filters to refine the users shown in the message rates chart. The message rates shown will correspond to the filtered rows"), 
                    helpText("If filtering / searching returns over 100 rows, overall message rates for the selected group will be shown"),
                    helpText("The numbers on the legend of the message rates chart correspond to the ID number of an individual in the first column of the table"),
                    helpText("Use the 'Reset filter' button to reset the search criteria"),
                    helpText("Specify the time window to view message rates for by clicking and dragging the smaller graph below the main message rates chart "))),
          br()
      ),
      
      #tabPanel(
        #"Hierarchy",
        #wellPanel(
          #h4("Corporate Hierarchy"),
          #helpText("Below is a tree showing the derived corporate hierarchy, as determined by the employee centrality rankings"),
          #visNetworkOutput("hierarchyGraph")
        #)
      #),
      
      tabPanel(
        "Aliases",
        wellPanel(
          h4("Alias Detection"),
          helpText("Input an email address in the search bar below to view any potential alias addresses that the individual might have"),
          textInput("aliasesSearchField", label = h5("Address Search"))
        ),
        wellPanel(
          h4("Aliases "),
          helpText("Listed below are the suggested aliases for the searched email address. An empty list signifies that no aliases were detected"),
          DT::dataTableOutput("aliasList")
        )
      )
    )
)

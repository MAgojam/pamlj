## This class prepares the pathdiagram. It does not produce the actual diagram to avoid
## issues in Windows with semPaths(). The actual diagram is produced in the .rederFun " in .b.R file.

Plotter <- R6::R6Class(
  "Plotter",
  cloneable=FALSE,
  class=FALSE,
  inherit = Scaffold,
  public=list(

      initialize=function(jmvobj,runner) {
            super$initialize(jmvobj)
            private$.results<-jmvobj$results
            private$.operator<-runner
            private$.results$plotnotes$setContent(" ")
      },

      initPlots=function() {
        ## PAMLj init plots
        private$.initCustom()

      },
      preparePlots=function(image, ggtheme, theme, ...) {
        
        
            ## first we prepare plots that should go anyway
        
            private$.prepare_diagram()
            private$.prepare_lav_diagram()

            ## then we prepare plots that should go if calculation has succeeded
        
            if (!private$.operator$ok || !private$.operator$plots$sensitivity) {
              if ("powerContour" %in% names(private$.results))
                            private$.results$powerContour$setVisible(FALSE)
              if ("powerEscurve" %in% names(private$.results))
                            private$.results$powerEscurve$setVisible(FALSE)
              if ("powerNcurve" %in% names(private$.results))
                            private$.results$powerNcurve$setVisible(FALSE)
              
              if (any(self$option("plot_contour"),self$option("plot_escurve"),self$option("plot_ncurve")))
                       private$.operator$warning<-list(topic="plotnotes",message="Plots cannot be produced.",head="error")
              return()
            }
            private$.prepareContour()
            private$.prepareEscurve()
            private$.prepareNcurve()
            private$.prepareCustom()
    
      },
      plot_contour = function(image,ggthem,them) {

        if (!self$option("plot_contour"))
            return()

        data<-image$state
        if (is.null(data)) return()
    #    par(mgp = c(4, 1, 0))
        off<-ifelse(min(data$y)<1e-04,5,4)
        par(mar = c(5, off+1, 4, 1) )

        res<-try_hard(
       
        filled.contour(data$x,data$y,data$z,color.palette =  image$state$plot_palette,
               key.title = {mtext("Power",3, .5)},
               ylab ="",
               xlab="Sample Size (N)",
               plot.axes={
                  axis(1, at=data$ticks, labels=data$tickslabels)
                  axis(2, at=data$yticks, labels=data$ytickslabels)
                  title(ylab = paste("Hypothetical effect size (",data$letter,")", sep = ""), mgp = c(off, 1, 0))
                  yor<-par()$usr[3]
                  xor<-par()$usr[1]
                  lines(data$x, data$yline, type = "l", lty = 1, lwd=2)
                  segments(xor,data$point.y,data$point.x,data$point.y, lwd=2)
                  segments(data$point.x,yor,data$point.x,data$point.y, lwd=2)
                  points(data$point.x,data$point.y,pch=21,bg="white",cex=1.5)
                 # mtext(paste("Hypothetical effect size (",data$letter,")", sep = ""), side = 2, line = 3) 
               }
    
            
           )
        )
       if (!isFALSE(res$error)) {
                   message<-paste0("Countour plot cannot be produced for the combination of parameters given in input.")
                   private$.operator$warning<-list(topic="plotnotes",message=message,head="error")
                   private$.results$powerContour$setVisible(FALSE)

       }

      },
      plot_curve= function(image,ggtheme,theme) {
         

        if (!self$option("plot_ncurve") && !self$option("plot_escurve"))
                return()

         cols = paml_palette("viridis")(10)
         state<-image$state
         if (is.null(state)) 
             return()
         cols = state$cols
         data <- state$data
         range <- max(data$x)-min(data$x)
         plot(data$x,data$y,  ty='n', 
              xaxt='n',
              ylab=state$ylab, xlab=state$xlab,
              ylim=c(0,1)
              )
         axis(1, at=state$ticks, labels=state$tickslabels)
#        axis(1, at=state$ticks)

         yrect <- seq(0,1,.1)
         yrect[1]<-yrect[1]-.5
         yrect[11]<-yrect[11]+.5
         yor<-par()$usr[3]
         xor<-par()$usr[1]

         for(i in 1:10){
              rect(par()$usr[1], yrect[i], par()$usr[2], yrect[i+1], border = NA,
                   col = cols[i])
         }
         lines(data$x,data$y,lwd=2)
         segments(xor,state$point.y,state$point.x,state$point.y, lwd=2)
         segments(state$point.x,yor,state$point.x,state$point.y, lwd=2)
         points(state$point.x,state$point.y,pch=21,bg="white",cex=1.5)
         mtext(state$text, adj = 1)
         
       },

      plot_custom= function(image,ggtheme,theme) {
         
        if (!private$.operator$ok || !private$.operator$plots$sensitivity) return()

        if (!is.something(image$state)) return()
        
         state<-image$state
         
         data<-state$data
         
         threed<-FALSE


         if (is.something(data$z)) {
           data$z<-factor(data$z)
           data<-data[order(data$z),]
           threed<-TRUE
         }

         dig=3
         ydif <- max(data$y)-min(data$y)
         xdif <- max(data$y)-min(data$y)

         .nudge<-ggplot2::position_nudge(y = ydif/18)

         if (threed) 
                    .aes <- ggplot2::aes(x=x,y=y,color=z)
         else
                    .aes <- ggplot2::aes(x=x,y=y)
                    
         p <- ggplot2::ggplot(data,.aes)
         p <- p + ggplot2::geom_line( linewidth=1.5)
         p <- p + ggplot2::geom_point(size=2, fill="white", shape=21)

         if (state$ticks) {
                                      if (max(data$y)>9) dig=0
                                      g <- ggplot2::ggplot_build(p)
                                      b <- g$layout$panel_params[[1]]$x$breaks
                                      b <- b[!is.na(b)]
                                      tdata<-data[data$x %in% b,]
                                      p <- p + ggplot2::geom_label(data=tdata,ggplot2::aes(x=x,y=y,label=round(y,digits=dig)),
                                      position = .nudge, alpha=0,label.size = NA)

         }
         p <- p + ggplot2::xlab(state$xlab) + ggplot2::ylab(state$ylab) 
         if (hasName(state,"zlab")) 
             p <- p  + ggplot2::guides(color=ggplot2::guide_legend(title=state$zlab))
        
         p <- p + ggtheme
         return(p)
       }
      
  ), # end of public
  private = list(
    .results=NULL,
    .operator=NULL,
    
    .prepareContour = function() {
      
     if (!self$option("plot_contour"))
              return()
     if (self$option("is_equi"))
              return()
       if (!("powerContour" %in% names(private$.results)))
           return()

      jinfo("PLOTTER: preparing contour plot")
      
      obj  <- private$.operator
      data <- private$.operator$data
      image<-private$.results$powerContour
      ## check the min-max for effect size

#      esmax <- obj$info$esmax
#      if (esmax < data$es) esmax<-data$es
#      esmin<-  obj$info$esmin

   
   
      ## check min-max for N


      ## determine the effect size min and max
      
      esmax <- data$es*obj$plots$esrange
      if (esmax > obj$info$esmax) esmax<-obj$info$esmax
      esmin <- data$es/obj$plots$esrange
      if (esmin < obj$info$esmin) esmin<-obj$info$esmin
      .data<-data
      .data$es<-esmin
      .data$n<-NULL
      nmax<-powervector(obj,.data)$n
      .data$es<-esmax*1.1
      .data$n<-NULL
      nmin<-powervector(obj,.data)$n

       if (nmin > data$n) {
          nmin<-  find_min_n(obj,.data)
          nmax<-  find_max_n(obj,data)
      }
      if (nmax< data$n) nmax<-round(data$n*1.5,digits=0)
      if (nmax<(nmin*2)) nmax=(nmin*2)
      point.x<-obj$data$n
      y <- seq(esmin,esmax,len=20)
      es <- y
      point.y <- data$es
      FLX<-identity
      FEX<-identity
      FLY<-identity
      FEY<-identity

      if (self$option("plot_log")) {
         FLX<-log
         FEX<-exp
         if (obj$info$loges(data$es)) {
            FLY<-log
            FEY<-exp
         }
      }

      
       x <- seq(FLX(nmin),FLX(nmax),len=20)
       n <- FEX(x)
       point.x<-FLX(obj$data$n)
       ticks<-seq(FLX(nmin),FLX(nmax),len=6)
       tickslabels<-round(FEX(ticks))
       y  <- seq(FLY(esmin),FLY(esmax),len=20)
       es <- FEY(y)
       point.y <- FLY(data$es)
       yticks <- seq(FLY(esmin),FLY(esmax),len=6)
       ytickslabels<-format(FEY(yticks),digits=3)
       ytickslabels<-sub("^0+", "", ytickslabels)
      .data <- cbind(n,obj$data)
      .data$es <- NULL
      .data$power[.data$power<.0501]<- .0501
       yline=powervector(obj,.data)[["es"]]
       yline=FLY(yline)
      .data <- cbind(n,obj$data)
      .data$power<-NULL
       out<-lapply(es,function(ind)  {
         .data$es<-ind
         powervector(obj,.data)[["power"]]
         })
       z<-do.call(cbind,out)

     
      image$setState(list(x=x,y=y,z=z,
                          point.x=point.x,point.y=point.y,
                          n=data$n,power=data$power,yline=yline,
                          ticks=ticks,
                          tickslabels=tickslabels,
                          yticks=yticks,
                          ytickslabels=ytickslabels,
                          letter=obj$info$letter,
                          plot_palette=paml_palette(obj$options$plot_palette)))

    },
     .prepareNcurve = function() {

      if (!self$option("plot_ncurve"))
                return()
      jinfo("PLOTTER: preparing N curve plot")
      
      obj  <- private$.operator
      data <- private$.operator$data
      image<-private$.results$powerNcurve
      ## check the min-max for effect size

      ## check min-max for N
      nmax<-find_max_n(obj,data)
      nmin<-find_min_n(obj,data)

       if (nmin >= data$n ) nmin<-data$n
       if (nmax < data$n) nmax<-round(data$n*1.5,digits=0)

        FLX<-identity
        FEX<-identity
        FLY<-identity
        FEY<-identity

        if (self$option("plot_log")) {
            FLX<-log
            FEX<-exp
        }

       x <- seq(FLX(nmin),FLX(nmax),len=20)
       n <- FEX(x)
       point.x<-FLX(obj$data$n)
       ticks<-seq(FLX(nmin),FLX(nmax),len=6)
       tickslabels<-round(FEX(ticks))
      .data<-obj$data
      .data[["n"]]<-NULL
      .data  <- cbind(n,.data)
      .data$power<-NULL
      
       ydata <- powervector(obj,.data)
       ydata$x <- x
       ydata$y <- ydata$power

       plot_palette<-paml_palette(obj$options$plot_palette)
       image$setState(list(data=ydata,
                            point.x = point.x,
                            point.y = obj$data$power,
                            ticks=ticks,
                            tickslabels=tickslabels,
                            xlab="Required Sample Size (N)",
                            ylab="Power",
                            text=paste(obj$info$letter,"=",round(data$es,digits=3)," ",greek_vector["alpha"],"=",round(data$sig.level,digits=3)),
                            cols=plot_palette(10)
                          ))


    },
    .prepareEscurve = function() {
      
       if (!self$option("plot_escurve"))
               return()
       if (!("powerEscurve" %in% names(private$.results))) 
            return()

        jinfo("PLOTTER: preparing Es curve plot")
        obj <- private$.operator
        data <- private$.operator$data
        image<-private$.results$powerEscurve
    ## check the min-max for effect size
      .data<-data
      .data$power<-.99
       esmax <- find_max_es(obj,.data)

      if (esmax < data$es) esmax<-data$es
      esmin<-  obj$info$esmin

  
        FLX<-identity
        FEX<-identity
  
        if (self$option("plot_log")) {
            if (obj$info$loges(esmax)) {
               FLX<-log
               FEX<-exp
            }
        }

       x <- seq(FLX(esmin),FLX(esmax),len=20)
       es <- FEX(x)
       point.x<-FLX(obj$data$es)
       ticks<- FLX(pretty(c(esmin,esmax),6))
       tickslabels<-round(FEX(ticks),digits=3)

        .data <- cbind(es,obj$data) 
        .data$power<-NULL
        ydata<-powervector(obj,.data)
        ydata$x <- x
        ydata$y <- ydata$power
        plot_palette<- paml_palette(obj$options$plot_palette)
        image$setState(list(data=ydata,
                            point.x = point.x,
                            point.y = private$.operator$data$power,
                            ticks=ticks,
                            tickslabels=tickslabels,
                            xlab="Hypothetical effect size",
                            ylab="Power",
                            text=paste("N =",data$n," ",greek_vector["alpha"],"=",round(data$sig.level,digits=3)),
                            cols=plot_palette(10)
                          ))
    },
    
     .initCustom    = function() {
       
        if (self$option("plot_y","none")) {
          return()
        }
        if (self$option("plot_x","none")) {
          return()
        }

        if (self$options$plot_x==self$options$plot_y) {
          self$warning<-list(topic="customnotes",message="Please define different parameters for the X and Y axis", head="note")          
          return()
        }

        if (self$options$plot_x_from==self$options$plot_x_to) {
            self$warning<-list(topic="customnotes",message="Please set a suitable range for custom plot X-axis values",head="error")          
            return()
      }

        if (self$options$plot_x_from>self$options$plot_x_to) {
            self$warning<-list(topic="customnotes",message="Please set a suitable range for custom plot X-axis values", head="error")          
            return()
        }
         jinfo("PLOTTER: init  custom plot")
         image<-private$.results$powerCustom
         z_values<-private$.test_z()
         y <- self$options$plot_y
         x <- self$options$plot_x
         image$setState(list(y=y, x=x, z=z_values))
       
     },
     .prepareCustom = function() {
      
        obj  <- private$.operator
        data <- private$.operator$data
        image<-private$.results$powerCustom
        
        if (is.null(image$state))
            return()
        z_values<-private$.test_z()

        jinfo("PLOTTER: preparing custom plot")

        what<-self$options$plot_x
        data[[what]]<-NULL
        ### check in values make sense ###
        xmin<-self$options$plot_x_from
        xmax<-self$options$plot_x_to
        ### here we check that the input makes sense, otherwise we adjust it
        switch (what,
                n =  {  
                      
                },
                power = {

                        if (xmin<.1) { 
                                      xmin <-.10
                                      self$warning<-list(topic="customnotes",message="Minimum power is set to .10", head="info")          
                                      }
                        if (xmax>.99) { 
                                      xmax  <- .99
                                      self$warning<-list(topic="customnotes",message="Max power is set to .99", head="info")          
                                      }
                        },
                es = {

                         esmax<-obj$info$esmax
                         esmin<-find_min_es(obj,data)
      
                        if (xmin < esmin) {
                                           xmin <-esmin
                                           self$warning<-list(topic="customnotes",message=paste("Minimum effect size is set to ",obj$info$letter,"=",esmin), head="info")          
                        }
                        
                        if (xmax > esmax) {
                                           xmax <-esmax
                                           self$warning<-list(topic="customnotes",message=paste("Max effect size is set to ",obj$info$letter,"=",esmax), head="info")          
                                          }

                        },
                sig.level = {
                        if (xmin< .0001) xmin <- 0.0001
                        if (xmax> .5) { 
                                       xmax  <- .5 
                                       self$warning<-list(topic="customnotes",message="Type I error max is set to .50", head="info")          
                                      }
                        }
        )
        x<-pretty(c(xmin,xmax),n=20)
      
        x[1]<-xmin
        x[length(x)]<-xmax
        
        data<-cbind(x,data)
        names(data)[1]<-what
        zlab<-NULL
  
        if (is.something(z_values)) {
          data[[self$options$plot_z]]<-NULL
          data<-merge(z_values,data)
          names(data)[1]<-self$options$plot_z
        }
        data[[self$options$plot_y]]<-NULL
        
        tryobj<-try_hard(powervector(private$.operator,data))

        if (!isFALSE(tryobj$error)) {
            self$warning<-list(topic="customnotes",message="The required plot cannot be produced (generic). Please update the plot settings", head="error")          
            return()
        } else 
           ydata<-tryobj$obj

        if (any(is.nan(ydata[[self$options$plot_y]]))) {
            self$warning<-list(topic="customnotes",message="The required plot cannot be produced (NaN produced). Please update the plot settings", head="error")          
            return()
        }
        
        names(ydata)[names(ydata)==self$options$plot_x]<-"x"
        names(ydata)[names(ydata)==self$options$plot_y]<-"y"
        names(ydata)[names(ydata)==self$options$plot_z]<-"z"
        if (hasName(ydata,"z"))
            zlab<-nicify_param(self$options$plot_z,short=T)

        image$setVisible(TRUE)
        image$setState(list(data=ydata,
                            ticks=self$option("plot_custom_labels"),
                            xlab=nicify_param(self$options$plot_x),
                            ylab=nicify_param(self$options$plot_y),
                            zlab=zlab))
    },
    .test_z = function() {
      
           obj  <- private$.operator
           data <- private$.operator$data

           z_values <- NULL
      
            if (self$option("plot_z","none"))
              return()
           
            if (self$options$plot_z %in% c(self$options$plot_x,self$options$plot_y)) {
                self$warning<-list(topic="customnotes",message="Multiple lines cannot be plotted for the parameters in Y or X axis.", head="warning")          
                return()
            }
           
            if (self$options$plot_z_lines == 0) {
                self$warning<-list(topic="customnotes",message="Please set the required number of lines")          
                return()
            } 
          
            z_values <- unlist(lapply(self$options$plot_z_value, function(x) try_hard(if (as.numeric(x) > 0) as.numeric(x))$obj))
            
            # if (!isFALSE(tryobj$error)) {
            #     self$warning<-list(topic="customnotes",message=paste("Values for",nicify_param(self$options$plot_z)," are not correct."), head="error")
            #     return()
            # }
            # z_values<-tryobj$obj
            
            if (is.null(z_values)) {
                self$warning<-list(topic="customnotes",message=paste("Please set a valid value of",nicify_param(self$options$plot_z)," for each line."), head="warning")          
                return()
             }
               
            if (length(z_values) != self$options$plot_z_lines) {
                self$warning<-list(topic="customnotes",
                                   message=paste("Please set a valid value of",nicify_param(self$options$plot_z)," for each line. Only",length(z_values)," curves are displayed."))          
            }

        what<-self$options$plot_z
        ### check in values make sense ###
        ### here we check that the input makes sense, otherwise we adjust it
        switch (what,
                n =  {  
                      xmin<-find_min_n(obj,data)
                      w<-(z_values < xmin)
                      if (any(w)) {
                       self$warning<-list(topic="customnotes",
                                   message="Value " %+% paste(z_values[w],collapse=", ") %+% " too small to estimates the required power parameters", head="warning")          
                                   z_values<-z_values[!w]
                      }
                      xmax<-find_max_n(obj,data)
                      w<-which(z_values < xmin)
                      if (any(w)>0) {
                       self$warning<-list(topic="customnotes",
                                  message="Value " %+% paste(z_values[w],collapse=", ") %+% " too large to estimates the required power parameters", head="warning")          
                                  z_values<-z_values[!w]
                      }
  
                },
                power = {
                        w<-(z_values < .1)
                        if (any(w)) { 
                                      self$warning<-list(topic="customnotes",message="Value " %+% paste(z_values[w],collapse=", ")  %+% "  smaller than the minimum estimable power", head="warning")          
                                      z_values<-z_values[!w]

                                      }
                        w<-(z_values > .99)
                        if (any(w)) { 
                                      self$warning<-list(topic="customnotes",message="Value " %+% paste(z_values[w],collapse=", ") %+% "  larger than the maximum estimable power", head="warning")          
                                      z_values<-z_values[!w]
                                      }
                        },
                es = {

                         esmax<-obj$info$esmax
                         esmin<-obj$info$esmin
                         w<-(z_values > esmax)
                        if (any(w)>0) { 
                                      self$warning<-list(topic="customnotes",message="Value " %+% paste(z_values[w],collapse=", ") %+% "  larger than the maximum estimable effect size.", head="warning")          
                                      z_values<-z_values[!w]

                                      }
                         w<-(z_values < esmin)
                         if (any(w)) { 
                                      self$warning<-list(topic="customnotes",message="Value " %+% paste(z_values[w],collapse=", ") %+% "  smaller than the minimum estimable effect size.", head="warning")          
                                      z_values<-z_values[!w]
                                      }


                        },
                sig.level = {
                         w<-(z_values < .0001)
                         if (any(w)) { 
                                      self$warning<-list(topic="customnotes",message="Value " %+% paste(z_values[w],collapse=", ") %+% "  smaller than the minimum Type I error rate (.0001).", head="warning")          
                                      z-values<-z_values[!w]
                                      }
                         w<-(z_values > .50)
                         if (any(w)) { 
                                      self$warning<-list(topic="customnotes",message="Value " %+% paste(z_values[w],collapse=", ") %+% "  larger than the maximum Type I error rate (.50).", head="warning")          
                                      z_values<-z_values[!w]
                                      }

                        }
        )
            
            return(z_values)
    
    },
    .prepare_diagram=function() {
      
              if (!self$option("diagram")) return()
              obj  <- private$.operator
              data <- private$.operator$plots$data
              image<-private$.results$diagram
              state<-list()
              jinfo("PLOTTER: preparing diagram")
              
              if (obj$options$mode == "medsimple") {
                        image$setSize(400,300)
                        state$enlarge<-1.2
                        state$coord<-matrix(c(1,2,1,2,3,3),ncol=2,nrow=3)
                        p<-matrix(NA,nrow=2,ncol=3)
                        p[2,1]<-1
                        p[1,2]<-2
                        p[2,3]<-3
                        state$p <- p
                        state$labels<-c("X","M","Y")
                        labs<-data[,c("a","b","cprime")]
                        lets<-c("a","b","c'")
                        goodvalues<-sapply(labs,function(x) {
                                                      if (is.na(x)) return("")
                                                      else return(paste0("=",format(x,digits=3)))})
                                            
                        labs        <- paste0(lets,goodvalues)
                        
                        state$edge.labels<-labs
                        
              } # end of medsimple
              
              
              if (obj$options$mode == "medcomplex") {
                  switch (obj$options$model_type,
                            twomeds = {
                                       state$enlarge<-1
                                       state$coord<-matrix(c( 1,2,
                                                              2,4,
                                                              1,3,
                                                              3,4,
                                                              1,4,
                                                              2,3,
                                                              3,2
                                                     ),ncol=2,byrow=T)

                                        p<-matrix(NA,nrow=3,ncol=3)
                                        p[2,1]<-1
                                        p[1,2]<-2
                                        p[3,2]<-3
                                        p[2,3]<-4
                                        state$p<-p
                                        
                                        pos<-rep(.5,7)
                                        pos[6]<-.4
                                        state$pos<-pos
                                        
                                        state$labels<-c("X","M"%+%sub1,"M"%+%sub2,"Y")
                                        labs<-data[,c("a1","b1","a2","b2","cprime","r12","r12")]
                                        lets<-c("a"%+%sub1,"b"%+%sub1,"a"%+%sub2,"b"%+%sub2,"c'","r"%+%sub1%+%sub2,"r12")
                                        goodvalues<-sapply(labs,function(x) {
                                                      if (is.na(x)) return("")
                                                      else return(paste0("=",format(x,digits=3)))})
                                            
                                        labs        <- paste0(lets,goodvalues)
                                       
                                        state$edge.labels <- labs
                                        state$curve <- c(0,0,0,0,0,-2)
                            },
                            threemeds = {
                                       state$enlarge<-.8
                                       state$coord<-matrix(c( 1,2,
                                                        2,5,
                                                        1,3,
                                                        3,5,
                                                        1,4,
                                                        4,5,
                                                        1,5,
                                                        2,3,
                                                        3,2,
                                                        2,4,
                                                        4,2,
                                                        3,4,
                                                        4,3
                                                        ),ncol=2,byrow=T)

                                       p<-matrix(NA,nrow=3,ncol=3)
                                       p[2,1]<-1
                                       p[1,2]<-2
                                       p[2,2]<-3
                                       p[3,2]<-4
                                       p[2,3]<-5
                                       state$p <- p

                                       pos<-rep(.5,13)
                                       pos[10]<-.42
                                       state$pos <- pos
                                       
                                       curve<-rep(0,13)
                                       curve[10]<--2.5
                                       state$curve<-curve
                                       
                                        state$labels<-c("X","M"%+%sub1,"M"%+%sub2,"M"%+%sub3,"Y")
                                        labs<-data[,c("a1","b1","a2","b2","a3","b3","cprime","r12","r12","r13","r13","r23","r23")]
                                        lets<-c("a"%+%sub1,"b"%+%sub1,
                                                "a"%+%sub2,"b"%+%sub2,
                                                "a"%+%sub3,"b"%+%sub3,"c'",
                                                "r"%+%sub1%+%sub2,"r12",
                                                "r"%+%sub1%+%sub3,"r13",
                                                "r"%+%sub2%+%sub3,"r23"
                                                )
                                        goodvalues<-sapply(labs,function(x) {
                                                      if (is.na(x)) return("")
                                                      else return(paste0("=",format(x,digits=3)))})
                                            
                                        labs        <- paste0(lets,goodvalues)
                                        state$edge.labels <- labs
                                        
                            },
                            twoserial = {
                                      state$enlarge<-.9
                                      state$coord<-matrix(c( 1,2,
                                                             2,4,
                                                             1,3,
                                                             3,4,
                                                             2,3,
                                                             1,4
                                                       ),ncol=2,byrow=T)
                                      p<-matrix(NA,nrow=2,ncol=5)
                                      p[2,1]<-1
                                      p[1,2]<-2
                                      p[1,4]<-3
                                      p[2,5]<-4
                                      state$p <- p
                                      

                                        state$labels<-c("X","M"%+%sub1,"M"%+%sub2,"Y")
                                        labs<-data[,c("a1","b1","a2","b2", "d1","cprime")]
                                        lets<-c("a"%+%sub1,"b"%+%sub1,
                                                "a"%+%sub2,"b"%+%sub2,
                                                "d"%+%sub1,
                                                "c'"
                                                )
                                        goodvalues<-sapply(labs,function(x) {
                                                      if (is.na(x)) return("")
                                                      else return(paste0("=",format(x,digits=3)))})
                                            
                                        labs        <- paste0(lets,goodvalues)
                                        state$edge.labels <- labs
                                        
                            }
                          
                          
                  ) # end of switch

              } # end of medcomplex
              
              
              image$setState(state)

    },

     .prepare_lav_diagram=function() {
       
          if (!self$option("lav_diagram")) return()
       
          obj  <- private$.operator
          if (!obj$ok) return()
          jinfo("PLOTTER: preparing path diagram")
          data <- private$.operator$data
          if (is.null(private$.operator$data$modelPop)) return()
          
          image<-private$.results$diagram
          
          model<-lavaan::lavaanify(private$.operator$data$modelPop)
          nodeLabels<-3
          nNodes<-length(nodeLabels)
          size<-16*exp(-nNodes/80)+1
          state=list(model=model,
                     sizeLat = size, 
                     sizeLat2 = size*.50, 
                     sizeMan=size*.70, 
                     sizeMan2=size*.35,
                     edge.label.cex =1.3)
          image$setState(state)

     }

  ) # end of private
) # end of class
    

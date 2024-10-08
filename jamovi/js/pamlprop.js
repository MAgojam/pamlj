var fun=require('./functions');

const events = {
  
    update: function(ui) {
         console.log("Updating analysis");
         fun.update_z_value(ui);
    },
    plot_x_changed: function(ui) {
      
         var plotx = ui.plot_x.value();
         
         switch (plotx) {
              case "n": 
                   ui.plot_x_from.setValue(10);
                   ui.plot_x_to.setValue(100);
                   break;
              case "power": 
                   ui.plot_x_from.setValue(.50);
                   ui.plot_x_to.setValue(.98);
                   break;
              case "es": 
                   ui.plot_x_from.setValue(0.1);
                   ui.plot_x_to.setValue(0.5);
                   break;

             default: 
                   ui.plot_x_from.setValue(0);
                   ui.plot_x_to.setValue(0);

           }
         

    },
    plot_z_changed: function(ui) {
      
     ui.plot_z_value.setValue([]);
     ui.plot_z_lines.setValue(1);
     fun.update_z_value(ui);
    },
    
    plot_z_lines_changed: function(ui) {
      
     console.log("plot_z_lines changed")      
     

      var n_lines=ui.plot_z_lines.value();
      if (n_lines < 1) {
          ui.plot_z_lines.setValue(1);
          return
      }
      if (n_lines > 5) {
          ui.plot_z_lines.setValue(5);
          return
      }
      fun.update_z_value(ui);
      
    },
    
    onChange_value_added: function(ui) {
      
    },
    onChange_value_removed: function(ui) {
      
    }


};

module.exports = events;


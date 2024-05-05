#' @export

# Temperature, conductivity and salinity data from Odyssey Logger
HOBO_parse <- function (file) {
  logger_record_df = data.frame(matrix(ncol=7, nrow=0))
  colnames(logger_record_df) <- c("Date", "Time", "DateTime", "Mesocosm", "Temperature", "Conductivity", "Salinity")
  
  sheet_list <- c("L01", "L06", "L08", "L10")
  for (sheet in sheet_list) {
    src <- readxl::read_excel(file, sheet = sheet)
    temp_df <- data.frame(src[, 2:3], "", sheet, src[, 5], src[, 7:8]) # columns: "Date", "Time", "", sheet, "Temperature CALIBRATED VALUE", "Salinity CALIBRATED VALUE", "Salinity (ppt)"
    # colnames(temp_df) <- colnames(logger_record_df); logger_record_df <- rbind(logger_record_df, temp_df)
    logger_record_df <- data.frame(mapply(c, logger_record_df, temp_df))
  }
  logger_record_df <- logger_record_df[grepl("[0-9]", logger_record_df$Temperature), ] # remove empty rows
  
  logger_record_df[, c("Temperature", "Conductivity", "Salinity")] <- dplyr::mutate_all(logger_record_df[, c("Temperature", "Conductivity", "Salinity")], function(x) {as.numeric(as.character(x))})
  logger_record_df$Salinity <- wql::ec2pss(logger_record_df$Conductivity, logger_record_df$Temperature)
  
  print("Summary of Odyssey data"); print(summary(logger_record_df))
  
  logger_record_df$DateTime <- as.POSIXct(paste0(logger_record_df$Date, " ", logger_record_df$Time), format="%d/%m/%Y %H:%M:%S", tz=Sys.timezone())
  
  return(logger_record_df)
}
# =======================================================================================================================================


if (sys.nframe() == 0) {
  setwd(file.path(paste0("C:/Users/", Sys.info()[["user"]], "/Desktop/DMB/Onset HOBO")))
  MESOCOSM_LIST <- c("L01", "L02", "L03", "L04", "L05", "L06", "L07", "L08", "L09", "L10", "L11", "L12")
  
  df_temperature <- data.frame()
  df_lux <- data.frame()
  for (mesocosm in MESOCOSM_LIST) {
    print(mesocosm)
    mesocosm_temp <- data.frame()
    
    for (folder in list.dirs()) {
      print(folder)
      
      for (file in list.files(path = folder, pattern = paste0("^", mesocosm, ".*csv$"))) {
        print(file)
        
        temp <- read.csv(file.path(folder, file), header = FALSE, na.strings = "")
        colnames(temp) <- temp[2, ]
        suppressWarnings(temp[, 3:4] <- sapply(temp[, 3:4], as.numeric))
        temp <- temp[!is.na(temp[3]), 2:4]
        
        mesocosm_temp <- rbind(mesocosm_temp, temp)
        
        
      }
    }
    if (dim(df_temperature)[2] == 0) {df_temperature <- merge(df_temperature, mesocosm_temp[, 1:2], all = TRUE)}
    df_temperature <- merge(df_temperature, mesocosm_temp[, 1:2], all = TRUE)
    
    if (dim(df_lux)[2] == 0) {df_lux <- merge(df_lux, mesocosm_temp[, c(1,3)], all = TRUE)}
    df_lux <- merge(df_lux, mesocosm_temp[, c(1,3)], all = TRUE)
    
  }

  colnames(df_temperature) <- c(colnames(df_temperature)[1], MESOCOSM_LIST)
  df_temperature$`Date Time, GMT+08:00` <- as.POSIXct(df_temperature$`Date Time, GMT+08:00`, format="%m/%d/%Y %I:%M:%S %p", tz=Sys.timezone())
  
  df_temperature_long <- tidyr::pivot_longer(df_temperature, cols = all_of(MESOCOSM_LIST), names_to = "Mesocosm")
  unique_datetime <- unique(df_temperature_long$`Date Time, GMT+08:00`)
  unique_datetime <- unique_datetime[!duplicated(as.Date(unique_datetime))] # remove date with more than one time points
  
  p_temperature <- ggplot2::ggplot(data = df_temperature_long, ggplot2::aes(x = `Date Time, GMT+08:00`, y = value, color = Mesocosm)) + ggplot2::geom_point(size=0.3, alpha=0.3) + ggplot2::geom_line() + ggplot2::theme(axis.text.x = ggplot2::element_text(vjust=1, hjust=1, angle = 45)) + ggplot2::facet_grid(Mesocosm~.) + ggplot2::scale_x_continuous(name = "DateTime", breaks = unique_datetime, labels = paste(unique_datetime)) 
  
  
  colnames(df_lux) <- c(colnames(df_lux)[1], MESOCOSM_LIST)
  df_lux$`Date Time, GMT+08:00` <- as.POSIXct(df_lux$`Date Time, GMT+08:00`, format="%m/%d/%Y %I:%M:%S %p", tz=Sys.timezone())
  
  df_lux_long <- tidyr::pivot_longer(df_lux, cols = all_of(MESOCOSM_LIST), names_to = "Mesocosm")
  unique_datetime <- unique(df_lux_long$`Date Time, GMT+08:00`)
  unique_datetime <- unique_datetime[!duplicated(as.Date(unique_datetime))] # remove date with more than one time points
  
  p_lux <- ggplot2::ggplot(data = df_lux_long, ggplot2::aes(x = `Date Time, GMT+08:00`, y = value, color = Mesocosm)) + ggplot2::geom_point(size=0.3, alpha=0.3) + ggplot2::geom_line() + ggplot2::theme(axis.text.x = ggplot2::element_text(vjust=1, hjust=1, angle = 45)) + ggplot2::facet_grid(Mesocosm~.) + ggplot2::scale_x_continuous(name = "DateTime", breaks = unique_datetime, labels = paste(unique_datetime)) 
  
}
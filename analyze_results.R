setwd("~/code/ruby/parse_vis_sites")

library('ggplot2')
library('ggthemes')
library('plyr')
library('lubridate')
library(scales)

dotws <- c('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
months <- c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec')
colors <- c('#D62728', '#FF7F0E', '#1F77B4')
colors <- c('#D62728', '#2CA02C', '#1F77B4')

output_dir <- "out"

all_filename <- "all.csv"
#flowing_input_filename <- "flowingdata.csv"
# info_input_filename <- "infosthetics.csv"

#flowing_data <- read.csv(flowing_input_filename, header = TRUE)
# info_data <- read.csv(info_input_filename, header = TRUE)

# data <- flowing_data
data <- read.csv(all_filename, header = TRUE)
data$ttime <- ymd_hms(data$tweet_time)
data$tltime <- ymd_hms(data$local_tweet_time)
data$month_string <- factor(months[data$month], levels = months)
data$local_time <- data$ttime + hours(as.integer(data$offset_hours))

fdata <- subset(data, source == 'flowingdata')
vdata <- subset(data, source == 'visualisingdata')
idata <- subset(data, source == 'infosthetics')


source_counts <- ddply(data, c('source'), summarize, count = length(source))
month_counts <- ddply(data, c('source', 'month_string'), summarize, count = length(month), percent = length(month) / source_counts[source_counts$source == source[[1]], 'count'])
dotw_counts <- ddply(data, c('source', 'dotw'), summarize, count = length(dotw), percent = length(month) / source_counts[source_counts$source == source[[1]], 'count'])
time_counts <- ddply(data, .(source,hour(ttime)), summarize, count = length(ttime), percent = length(ttime) / source_counts[source_counts$source == source[[1]], 'count'])
local_time_counts <- ddply(data, .(source,hour(ttime + hours(as.integer(offset_hours)))), summarize, count = length(ttime), percent = length(ttime) / source_counts[source_counts$source == source[[1]], 'count'])
colnames(local_time_counts) <- c('source', 'hour', 'count', 'percent')
colnames(time_counts) <- c('source', 'hour', 'count', 'percent')
p <- ggplot(fdata, aes(x = hour(ttime)))
p <- p + geom_histogram(binwidth = 1, aes(y = (..count..)/sum(..count..))) + scale_y_continuous('% posted', labels = percent) + scale_x_discrete('Hour of the day') + theme_economist()
print(p)

# ---
# posts by hour
# faceted by source
# ---
#tweeted_data <- subset(data, !is.na(offset_hours))
p <- ggplot(time_counts, aes(x = hour, y = percent, fill = source))
p <- p + geom_bar(stat = 'identity', binwidth = 1) + scale_y_continuous('% Posted', labels = percent) + scale_fill_manual(values = colors)
p <- p + scale_x_discrete('Hour of the day', limits = 0:23) + labs(title = 'Posts by Hour (UTC)')+ theme_economist() + facet_grid(source~ .) +  opts(legend.position = "none") 
p
image_name <- paste(output_dir, '/', 'post_by_hour_facet_source_utc', '.png', sep='')
png(image_name, width = 790, height = 800)
print(p)
dev.off()

p <- ggplot(local_time_counts, aes(x = hour, y = percent, fill = source))
p <- p + geom_bar(stat = 'identity', binwidth = 1) + scale_y_continuous('% Posted', labels = percent) + scale_fill_manual(values = colors)
p <- p + scale_x_discrete('Hour of the day', limits = 0:23) + labs(title = 'Posts by Hour (Local)')+ theme_economist() + facet_grid(source~ .) +  opts(legend.position = "none") 
p
image_name <- paste(output_dir, '/', 'post_by_hour_facet_source_local', '.png', sep='')
png(image_name, width = 790, height = 800)
print(p)
dev.off()

midnight_tweets <- subset(fdata, hour(ttime + hours(as.integer(offset_hours))) == 0)
hist(minute(midnight_tweets$ttime), breaks = 60)

# ---
# fdata post by time
# broekn up by month
# ---
p <- ggplot(fdata, aes(x = hour(ttime + hours(as.integer(offset_hours))), fill = colors[1])) 
p <- p + geom_histogram(binwidth = 1, aes(y = (..count..)/sum(..count..), fill = (..count..)/sum(..count..)))
p <- p + scale_y_continuous('% posted',  breaks = c(0.00, 0.05), labels = c('', '5%')) + facet_grid(month_string ~ .) + scale_fill_gradient(name = 'count', low = '#000000', high = colors[1], labels = percent) + theme_economist() + labs(title = 'FlowingData Posts by Hour (Local), Broken up by Month') + scale_x_discrete('Hour of the day', limits = 0:23) 
p
image_name <- paste(output_dir, '/', 'post_by_hour_facet_month', '.png', sep='')
png(image_name, width = 790, height = 800)
print(p)
dev.off()


#scale_x_datetime(format="%H:%M:%S")


# ---
# day of the week
# line plot
# ---
p <- ggplot(dotw_counts, aes(x = factor(dotw, levels = dotws), y = percent, group = source, colour = source))
p <- p + geom_line(size= 2) + labs(title = 'Posts by Day of the Week', colour = '') + xlab('') + scale_y_continuous('% Posted', labels = percent) + theme_economist()  + scale_colour_manual(values = colors)
p
image_name <- paste(output_dir, '/', 'post_by_dotw', '.png', sep='')
png(image_name, width = 790, height = 500)
print(p)
dev.off()


# ---
# month
# ---
p <- ggplot(month_counts, aes(x = month_string, y = percent, group = source, colour = source))
p <- p + geom_line(size = 2)  + labs(colour = '') + labs(title = 'Posts by Month') + xlab('Month') +  scale_y_continuous('% Posted', labels = percent) + theme_economist()+ scale_colour_manual(values = colors)
p
image_name <- paste(output_dir, '/', 'post_by_month', '.png', sep='')
png(image_name, width = 790, height = 500)
print(p)
dev.off()

p <- ggplot(data, aes(month))
p + geom_bar() + facet_grid(source ~ .)

p <- ggplot(data, aes(source, y = (..count..)/sum(..count..), fill = factor(dotw, levels = dotws)))
p + geom_bar() + coord_flip()

# ---
# stacked bar chart
# ---
blues <- rev(c('#EFF3FF', '#C6DBEF', '#9ECAE1', '#6BAED6', '#4292C6', '#2171B5', '#084594'))
oranges <- rev(c('#FEEDDE', '#FDD0A2', '#FDAE6B', '#FD8D3C', '#F16913', '#D94801', '#8C2D04'))
p <- ggplot(dotw_counts, aes(x = source, y = percent, fill = factor(dotw, levels = dotws) ))
p <- p + geom_bar() + labs(fill= '') + coord_flip() + scale_y_continuous('% Posted', labels = percent) + theme_economist() + scale_fill_manual(name = '', values = oranges)
p
image_name <- paste(output_dir, '/', 'posts_by_dotw_stacked', '.png', sep='')
png(image_name, width = 790, height = 500)
print(p)
dev.off()

p <- ggplot(data, aes(x =factor(dotw, levels = dotws), fill = source))
p + geom_density()

shorter <- subset(data, words < 1000)
p <- ggplot(shorter, aes(words))
p + geom_histogram(binwidth = 20) + facet_grid(source ~ .)

subset(data, words > 200)
subset(data, words < 20)

p <- ggplot(data, aes(factor(dotw, levels = dotws), words))
p + geom_boxplot()

p <- ggplot(data, aes(links))
p + geom_bar(binwidth = 1.0)

subset(data, links > 10)

mean(data$links)


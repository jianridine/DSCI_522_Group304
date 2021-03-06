# author: Group 304 (Robert Pimentel)
# date: 2020-01-23

"This script produces 3 histogram comparing FSA average scores (Numeracy, Reading, and Writing) for students in Public schools vs Independent Schools
 Histograms include lines depicting the average and a 95% confidence interval

Usage: plot_publicindep_histogram.R <arg1> --arg2=<arg2> --arg3=<arg3> --arg4=<arg4> --arg5=<arg5>

Options:
<arg1>            File path (and filename) to the data (required positional argument); example: 'data/clean_data.csv'
--arg2=<arg2>     Output Directory for plots (required positional argument); example: '/img/'
--arg3=<arg3>     File path (and filename) of output Numeracy score histogram (required positional argument); example: 'fig_pi_numeracy.png'
--arg4=<arg4>     File path (and filename) of output Reading score histogram (required positional argument); example: 'fig_pi_reading.png'
--arg5=<arg5>     File path (and filename) of output Writing score histogram (required positional argument); example: 'fig_pi_writing.png'

" -> doc

# Example:
# Rscript src/plot_publicindep_histogram.R 'data/clean_data.csv' --arg2='img/' --arg3='fig_pi_histogram_numeracy.png' --arg4='fig_pi_histogram_reading.png' --arg5='fig_pi_histogram_writing.png'

# Load require Libraries to write the script.

library(docopt)
library(readr)
library(tidyverse)
library(infer)
library(repr)
library(testthat)
library(cowplot)

opt <- docopt(doc)

#########################

# Tests that the input link is a link to a csv file
test_input <- function(){
  test_that("The clean_data file_path/file_name should be a .csv file.",{
    expect_match(opt$arg1, ".csv")
  })
}
test_input()

# Tests that the outputs are all png files
test_output <- function(){
  test_that("The output should all be .png files.",{
    expect_match(opt$arg2, "img")
    expect_match(opt$arg3, ".png")
    expect_match(opt$arg4, ".png")
    expect_match(opt$arg5, ".png")
  })
}
test_output()

# READ CLEAN DATA
#df <- read_csv('../data/clean_data.csv')
df = read_csv(opt$arg1)

# DATA WRANGLING
pub_ind_num <- df %>%
  filter(fsa_skill_code == "Numeracy", sub_population == "ALL STUDENTS")

pub_ind_read <- df %>%
  filter(fsa_skill_code == "Reading", sub_population == "ALL STUDENTS")

pub_ind_write <- df %>%
  filter(fsa_skill_code == "Writing", sub_population == "ALL STUDENTS")

pub_ind_num$public_or_independent <- factor(pub_ind_num$public_or_independent, 
                                            levels = c('BC Independent School', 'BC Public School'))
# DEFINE SUBGROUPS
subgroup <- function(group){
  sub_group <- df %>%
    filter(sub_population == group)
}

all_students <- subgroup('ALL STUDENTS') 
female <- subgroup('FEMALE') 
male <- subgroup('MALE')
aboriginal <- subgroup('ABORIGINAL')
non_aboriginal <- subgroup('NON ABORIGINAL') 
eng_lang_learner <- subgroup('ENGLISH LANGUAGE LEARNER') 
non_eng_lang_learner<- subgroup('NON ENGLISH LANGUAGE LEARNER') 
special <- subgroup('SPECIAL NEEDS NO GIFTED')

#CONFINDENCE INTERVAL FUNCTION
set.seed(1234)
ci_ind <- function(df, skill, ind, size=50){
  one_sample <- df %>%
    filter(fsa_skill_code == skill & public_or_independent == ind) %>%
    rep_sample_n(size) %>%
    ungroup() %>%
    select(score)
  one_sample %>%
    rep_sample_n(size, reps = 5000, replace = TRUE) %>%
    summarize(stat = mean(score)) %>%
    get_ci()
}


######---------- NUMERACY RESULTS------------#########

#CALCULATE AVERAGES
pub_ind_numeracy <- df %>%
  filter(fsa_skill_code == "Numeracy") %>%
  group_by(sub_population, public_or_independent) %>%
  summarise(avg = mean(score))

#CALCULATE CONFIDENCE INTERVALS

low <- c(ci_ind(aboriginal, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(aboriginal, "Numeracy", "BC Public School")[[1]],
         ci_ind(all_students, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(all_students, "Numeracy", "BC Public School")[[1]],
         ci_ind(eng_lang_learner, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(eng_lang_learner, "Numeracy", "BC Public School")[[1]],
         ci_ind(female, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(female, "Numeracy", "BC Public School")[[1]],
         ci_ind(male, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(male, "Numeracy", "BC Public School")[[1]],
         ci_ind(non_aboriginal, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(non_aboriginal, "Numeracy", "BC Public School")[[1]],
         ci_ind(non_eng_lang_learner, "Numeracy", "BC Independent School")[[1]], 
         ci_ind(non_eng_lang_learner, "Numeracy", "BC Public School")[[1]],
         ci_ind(special, "Numeracy", "BC Independent School", 30)[[1]], 
         ci_ind(special, "Numeracy", "BC Public School", 30)[[1]])

high <- c(ci_ind(aboriginal, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(aboriginal, "Numeracy", "BC Public School")[[2]],
          ci_ind(all_students, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(all_students, "Numeracy", "BC Public School")[[2]],
          ci_ind(eng_lang_learner, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(eng_lang_learner, "Numeracy", "BC Public School")[[2]],
          ci_ind(female, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(female, "Numeracy", "BC Public School")[[2]],
          ci_ind(male, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(male, "Numeracy", "BC Public School")[[2]],
          ci_ind(non_aboriginal, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(non_aboriginal, "Numeracy", "BC Public School")[[2]],
          ci_ind(non_eng_lang_learner, "Numeracy", "BC Independent School")[[2]], 
          ci_ind(non_eng_lang_learner, "Numeracy", "BC Public School")[[2]],
          ci_ind(special, "Numeracy", "BC Independent School", 30)[[2]], 
          ci_ind(special, "Numeracy", "BC Public School", 30)[[2]])


sum_num <- tibble("sub_population" = pub_ind_numeracy$sub_population,
                  "public_or_independent" = pub_ind_numeracy$public_or_independent,
                  "avg" = pub_ind_numeracy$avg,
                  "2.5%" = low,
                  "97.5%" = high)

# FILTER by ALL-STUDENTS and Generate Histogram for Numeracy
pub_ind_num_stat <- sum_num %>% filter(sub_population == "ALL STUDENTS")

pi_hist_num <- pub_ind_num %>%
  ggplot( aes(x=score, fill=reorder(public_or_independent, score))) +
  geom_histogram( color="#e9ecef", alpha=0.5, position = 'identity', bins = 50) +
  geom_vline(xintercept = pub_ind_num_stat [[1,3]], color = "blue", size = .9) +
  geom_vline(xintercept = pub_ind_num_stat [[2,3]], color = "black", size = .9) +
  geom_vline(xintercept = c(pub_ind_num_stat [[1,4]], pub_ind_num_stat [[1,5]]),
             color = "blue", lty = 2, size = .7) + 
  geom_vline(xintercept = c(pub_ind_num_stat [[2,4]], pub_ind_num_stat [[2,5]]),
             color = "black", lty = 2, size = .7) +
  scale_fill_manual(values=c("#69b3a2", "#404080")) +
  annotate("text", x = 630, y = 1200, color = 'blue', size=6, label = paste("mean = ", round(pub_ind_num_stat [[1,3]], 2))) +
  annotate("text", x = 280, y = 1200, color = 'black', size=6, label = paste("mean = ", round(pub_ind_num_stat [[2,3]], 2))) +
  annotate("text", x = 670, y = 1100, , color = 'blue', size=6, label = paste(95,"% CI = [",
                                                                      round(pub_ind_num_stat [[1,4]], 2),",",round(pub_ind_num_stat [[1,5]], 2),"]")) +
  annotate("text", x = 320, y = 1100, color = 'black', size=6, label = paste(95,"% CI = [",
                                                                     round(pub_ind_num_stat [[2,4]], 2),",",round(pub_ind_num_stat [[2,5]], 2),"]")) +
  labs(y = "Counts",
       x = "Average Score",
       fill = "School Type",
       title = "FSA Numeracy Test Scores\n(2007/08 - 2018/19)") +
  labs(fill="") +
  theme_bw(base_size=17)+
  theme(plot.title = element_text(size = 24),
        axis.text.x = element_text(size =14),
        axis.title.x = element_text(size = 18))

pi_hist_num <- pi_hist_num + theme(legend.position = c(.30, .98),
                                   legend.justification = c("right", "top"))

# Create subdirectory folder if it does not exist
try({
  dir.create(opt$arg2)
})

# Save FSA numerical histogram plot
ggsave(paste0(opt$arg2, opt$arg3), width = 8, height = 5)


######---------- READING RESULTS------------#########

#CALCULATE AVERAGES
pub_ind_reading <- df %>%
  filter(fsa_skill_code == "Reading") %>%
  group_by(sub_population, public_or_independent) %>%
  summarise(avg = mean(score))

#CALCULATE CONFIDENCE INTERVALS

low <- c(ci_ind(aboriginal, "Reading", "BC Independent School")[[1]], 
         ci_ind(aboriginal, "Reading", "BC Public School")[[1]],
         ci_ind(all_students, "Reading", "BC Independent School")[[1]], 
         ci_ind(all_students, "Reading", "BC Public School")[[1]],
         ci_ind(eng_lang_learner, "Reading", "BC Independent School")[[1]], 
         ci_ind(eng_lang_learner, "Reading", "BC Public School")[[1]],
         ci_ind(female, "Reading", "BC Independent School")[[1]], 
         ci_ind(female, "Reading", "BC Public School")[[1]],
         ci_ind(male, "Reading", "BC Independent School")[[1]], 
         ci_ind(male, "Reading", "BC Public School")[[1]],
         ci_ind(non_aboriginal, "Reading", "BC Independent School")[[1]], 
         ci_ind(non_aboriginal, "Reading", "BC Public School")[[1]],
         ci_ind(non_eng_lang_learner, "Reading", "BC Independent School")[[1]], 
         ci_ind(non_eng_lang_learner, "Reading", "BC Public School")[[1]],
         ci_ind(special, "Reading", "BC Independent School",30)[[1]], 
         ci_ind(special, "Reading", "BC Public School",30)[[1]])

high <- c(ci_ind(aboriginal, "Reading", "BC Independent School")[[2]], 
          ci_ind(aboriginal, "Reading", "BC Public School")[[2]],
          ci_ind(all_students, "Reading", "BC Independent School")[[2]], 
          ci_ind(all_students, "Reading", "BC Public School")[[2]],
          ci_ind(eng_lang_learner, "Reading", "BC Independent School")[[2]], 
          ci_ind(eng_lang_learner, "Reading", "BC Public School")[[2]],
          ci_ind(female, "Reading", "BC Independent School")[[2]], 
          ci_ind(female, "Reading", "BC Public School")[[2]],
          ci_ind(male, "Reading", "BC Independent School")[[2]], 
          ci_ind(male, "Reading", "BC Public School")[[2]],
          ci_ind(non_aboriginal, "Reading", "BC Independent School")[[2]], 
          ci_ind(non_aboriginal, "Reading", "BC Public School")[[2]],
          ci_ind(non_eng_lang_learner, "Reading", "BC Independent School")[[2]], 
          ci_ind(non_eng_lang_learner, "Reading", "BC Public School")[[2]],
          ci_ind(special, "Reading", "BC Independent School",30)[[2]], 
          ci_ind(special, "Reading", "BC Public School",30)[[2]])


sum_read <- tibble("sub_population" = pub_ind_reading$sub_population,
                   "public_or_independent" = pub_ind_reading$public_or_independent,
                   "avg" = pub_ind_reading$avg,
                   "2.5%" = low,
                   "97.5%" = high)

# FILTER by ALL-STUDENTS and Generate Histogram for Reading
pub_ind_read_stat <- sum_read %>% filter(sub_population == "ALL STUDENTS")

pi_hist_read <- pub_ind_read %>%
  ggplot( aes(x=score, fill=reorder(public_or_independent, score))) +
  geom_histogram( color="#e9ecef", alpha=0.7, position = 'identity', bins = 50) +
  geom_vline(xintercept = pub_ind_read_stat [[1,3]], color = "blue", size = .9) +
  geom_vline(xintercept = pub_ind_read_stat [[2,3]], color = "black", size = .9) +
  geom_vline(xintercept = c(pub_ind_read_stat [[1,4]], pub_ind_read_stat [[1,5]]),
             color = "blue", lty = 2, size = .7) + 
  geom_vline(xintercept = c(pub_ind_read_stat [[2,4]], pub_ind_read_stat [[2,5]]),
             color = "black", lty = 2, size = .7) +
  scale_fill_manual(values=c("#69b3a2", "#404080")) +
  annotate("text", x = 630, y = 1500, color = 'blue', size=6, label = paste("mean = ", round(pub_ind_read_stat [[1,3]], 2))) +
  annotate("text", x = 280, y = 1500, color = 'black', size=6, label = paste("mean = ", round(pub_ind_read_stat [[2,3]], 2))) +
  annotate("text", x = 670, y = 1375, , color = 'blue', size=6, label = paste(95,"% CI = [",
                                                                      round(pub_ind_read_stat [[1,4]], 2),",",round(pub_ind_read_stat [[1,5]], 2),"]")) +
  annotate("text", x = 320, y = 1375, color = 'black', size=6, label = paste(95,"% CI = [",
                                                                     round(pub_ind_read_stat [[2,4]], 2),",",round(pub_ind_read_stat [[2,5]], 2),"]")) +
  labs(y = "Counts",
       x = "Average Score",
       fill = "School Type",
       title = "FSA Reading Test Scores\n(2007/08 - 2018/19)") +
  labs(fill="") +
  theme_bw(base_size=17)+
  theme(plot.title = element_text(size = 24),
        axis.text.x = element_text(size =14),
        axis.title.x = element_text(size = 18))

pi_hist_read <- pi_hist_read + theme(legend.position = c(.30, .98),
                                     legend.justification = c("right", "top"))

# Create subdirectory folder if it does not exist
try({
  dir.create(opt$arg2)
})

# Save FSA reading histogram plot
ggsave(paste0(opt$arg2, opt$arg4), width = 8, height = 5)

######--------NUMERACY/READING ONE PLOT----#########

theme_set(theme_cowplot())
plot <- plot_grid(pi_hist_num, pi_hist_read)

#Save plot in subdirectory folder resutls
try({
  dir.create(opt$arg2)
})
# Save FSA numeracy and reading histogram in a single plot
ggsave(paste0(opt$arg2, "fig_pi_histograms_join_num_read.png"), width = 20, height = 7)


######---------- WRITING RESULTS------------#########

#CALCULATE AVERAGES
pub_ind_writing <- df %>%
  filter(fsa_skill_code == "Writing") %>%
  group_by(sub_population, public_or_independent) %>%
  summarise(avg = mean(score))

#CALCULATE CONFIDENCE INTERVALS

low <- c(ci_ind(aboriginal, "Writing", "BC Independent School")[[1]], 
         ci_ind(aboriginal, "Writing", "BC Public School")[[1]],
         ci_ind(all_students, "Writing", "BC Independent School")[[1]], 
         ci_ind(all_students, "Writing", "BC Public School")[[1]],
         ci_ind(eng_lang_learner, "Writing", "BC Independent School")[[1]], 
         ci_ind(eng_lang_learner, "Writing", "BC Public School")[[1]],
         ci_ind(female, "Writing", "BC Independent School")[[1]], 
         ci_ind(female, "Writing", "BC Public School")[[1]],
         ci_ind(male, "Writing", "BC Independent School")[[1]], 
         ci_ind(male, "Writing", "BC Public School")[[1]],
         ci_ind(non_aboriginal, "Writing", "BC Independent School")[[1]], 
         ci_ind(non_aboriginal, "Writing", "BC Public School")[[1]],
         ci_ind(non_eng_lang_learner, "Writing", "BC Independent School")[[1]], 
         ci_ind(non_eng_lang_learner, "Writing", "BC Public School")[[1]],
         ci_ind(special, "Writing", "BC Independent School", 30)[[1]], 
         ci_ind(special, "Writing", "BC Public School", 30)[[1]])

high <- c(ci_ind(aboriginal, "Writing", "BC Independent School")[[2]], 
          ci_ind(aboriginal, "Writing", "BC Public School")[[2]],
          ci_ind(all_students, "Writing", "BC Independent School")[[2]], 
          ci_ind(all_students, "Writing", "BC Public School")[[2]],
          ci_ind(eng_lang_learner, "Writing", "BC Independent School")[[2]], 
          ci_ind(eng_lang_learner, "Writing", "BC Public School")[[2]],
          ci_ind(female, "Writing", "BC Independent School")[[2]], 
          ci_ind(female, "Writing", "BC Public School")[[2]],
          ci_ind(male, "Writing", "BC Independent School")[[2]], 
          ci_ind(male, "Writing", "BC Public School")[[2]],
          ci_ind(non_aboriginal, "Writing", "BC Independent School")[[2]], 
          ci_ind(non_aboriginal, "Writing", "BC Public School")[[2]],
          ci_ind(non_eng_lang_learner, "Writing", "BC Independent School")[[2]], 
          ci_ind(non_eng_lang_learner, "Writing", "BC Public School")[[2]],
          ci_ind(special, "Writing", "BC Independent School",30)[[2]], 
          ci_ind(special, "Writing", "BC Public School",30)[[2]])


sum_write <- tibble("sub_population" = pub_ind_writing$sub_population,
                    "public_or_independent" = pub_ind_writing$public_or_independent,
                    "avg" = pub_ind_writing$avg,
                    "2.5%" = low,
                    "97.5%" = high)

# FILTER by ALL-STUDENTS and Generate Histogram for Writing
pub_ind_write_stat <- sum_write %>% filter(sub_population == "ALL STUDENTS")

pi_hist_write <- pub_ind_write %>%
  ggplot( aes(x=score, fill=reorder(public_or_independent, score))) +
  geom_histogram( color="#e9ecef", alpha=0.7, position = 'identity', bins = 50) +
  geom_vline(xintercept = pub_ind_write_stat [[1,3]], color = "blue") +
  geom_vline(xintercept = pub_ind_write_stat [[2,3]], color = "red") +
  geom_vline(xintercept = c(pub_ind_write_stat [[1,4]], pub_ind_write_stat [[1,5]]),
             color = "blue", lty = 2) + 
  geom_vline(xintercept = c(pub_ind_write_stat [[2,4]], pub_ind_write_stat [[2,5]]),
             color = "red", lty = 2) +
  scale_fill_manual(values=c("#69b3a2", "#404080")) +
  #annotate("text", x = 610, y = 1500, color = 'blue', label = paste("mean = ", round(pub_ind_write_stat [[1,3]], 2))) +
  #annotate("text", x = 260, y = 1500, color = 'red', label = paste("mean = ", round(pub_ind_write_stat [[2,3]], 2))) +
  # annotate("text", x = 650, y = 1350, color = 'blue', label = paste(95,"% CI = [",
  #                                     round(pub_ind_write_stat [[1,4]], 2),",",round(pub_ind_write_stat [[1,5]], 2),"]")) +
  # annotate("text", x = 300, y = 1350, color = 'red', label = paste(95,"% CI = [",
  #                                     round(pub_ind_write_stat [[2,4]], 2),",",round(pub_ind_write_stat [[2,5]], 2),"]")) +
  labs(y = "Counts",
       x = "Average Score",
       fill = "School Type",
       title = "FSA Writing Test Scores\n(2007/08 - 2018/19)") +
  labs(fill="") +
  theme_bw() +
  theme(plot.title = element_text(size = 12),
        axis.text.x = element_text(size =10),
        axis.title.x = element_text(size = 10))

pi_hist_write + theme(legend.position = "bottom")

# Create subdirectory folder if it does not exist
try({
  dir.create(opt$arg2)
})

# Stops the script from creating a Rplots.pdf file:
# Check whether the unwanted file exists and removes it
file.exists("Rplots.pdf")
file.remove("Rplots.pdf")

# Save FSA writing histogram plot
ggsave(paste0(opt$arg2, opt$arg5), width = 8, height = 5)



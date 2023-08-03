# activate required packages

library(tidyverse)
library(broom)
library(ggeffects)
library(cowplot)
theme_set(theme_cowplot(12))

# eDNA results and environmental data can be downloaded from the Arctic Data archive System (ADS) managed by the National Institute of Polar Research, Japan, under the accession number A20230323-002 (https://ads.nipr.ac.jp/dataset/A20230323-002).

# import result file

result <- read_csv("./Boreogadus_eDNA_data.csv")

eDNA_result <- result %>% 
  select(site = Site_name, 
         wt = `Water_temperature_(°C)`, 
         sal = Salinity, 
         chl = `Chlorophyll_a_flurescence_(RFU)`, 
         topo = Topology, 
         sampling_depth = `Sampling_depth_(m)`,
         quantity = `Quantity_of_polar_cod_eDNA_(copies/reaction)`
  ) %>% 
  mutate(presence = if_else(quantity > 0, 1, 0))

# make a data file for logistic regression

Bosa_presence <- eDNA_result %>% 
  filter(sampling_depth == 4.5) %>% 
  mutate(log_chl = log(chl)) %>% 
  select(presence, wt, sal, log_chl, topo)

# model selection

model <- glm(presence ~ ., family = binomial("logit"), data =  Bosa_presence)

sink("./Model_selection.txt")
MASS::stepAIC(model, direction = "backward") # MASSを読み込むとselectがdplyrと衝突するので都度使う。
sink()

# significance of coefficients

sink("./Model_selection_summary.txt")
print("presence ~ wt + sal + log_chl + topology")
summary(glm(presence ~ ., family = binomial("logit"), data =  Bosa_presence))
print("presence ~ wt + sal + topology")
summary(glm(presence ~ ., family = binomial("logit"), data =  select(Bosa_presence, c("presence", "wt", "sal", "topo"))))
print("presence ~ wt + sal")
summary(glm(presence ~ ., family = binomial("logit"), data =  select(Bosa_presence, c("presence", "wt", "sal"))))
print("presence ~ wt")
summary(glm(presence ~ ., family = binomial("logit"), data =  select(Bosa_presence, c("presence", "wt"))))
sink()

# calculate odds ratio

full <- glm(presence ~ ., family = binomial("logit"), data =  Bosa_presence) %>% 
  tidy() %>% 
  mutate(odds_ratio = exp(estimate)) %>% 
  mutate(CI_low = exp(estimate - 1.96 * std.error)) %>%
  mutate(CI_high = exp(estimate + 1.96 * std.error)) %>% 
  mutate(model = "presence ~ wt + sal + log_chl + topo") %>% 
  relocate(model)

mod1 <- glm(presence ~ ., family = binomial("logit"), data =  select(Bosa_presence, c("presence", "wt", "sal", "topo"))) %>% 
  tidy() %>% 
  mutate(odds_ratio = exp(estimate)) %>% 
  mutate(CI_low = exp(estimate - 1.96 * std.error)) %>%
  mutate(CI_high = exp(estimate + 1.96 * std.error)) %>% 
  mutate(model = "presence ~ wt + sal + topo") %>% 
  relocate(model)

mod2 <- glm(presence ~ ., family = binomial("logit"), data =  select(Bosa_presence, c("presence", "wt", "sal"))) %>% 
  tidy() %>% 
  mutate(odds_ratio = exp(estimate)) %>% 
  mutate(CI_low = exp(estimate - 1.96 * std.error)) %>%
  mutate(CI_high = exp(estimate + 1.96 * std.error)) %>% 
  mutate(model = "presence ~ wt + sal") %>% 
  relocate(model)

mod3 <- glm(presence ~ ., family = binomial("logit"), data =  select(Bosa_presence, c("presence", "wt"))) %>% 
  tidy() %>% 
  mutate(odds_ratio = exp(estimate)) %>% 
  mutate(CI_low = exp(estimate - 1.96 * std.error)) %>%
  mutate(CI_high = exp(estimate + 1.96 * std.error)) %>% 
  mutate(model = "presence ~ wt") %>% 
  relocate(model)

Model_selection_results <- bind_rows(full, mod1, mod2, mod3) %>% 
  mutate(signif = if_else(p.value < 0.05, "*", "")) %>%
  mutate(signif = if_else(p.value < 0.01, "**", signif)) %>%
  mutate(signif = if_else(p.value < 0.001, "***", signif))

write_csv(Model_selection_results, "./Model_selection_results.csv")

# plot the best model

best <- eval(models$call)

model_predict <- ggpredict(best, terms = "wt[all]")

param_at_50 <- round((log(0.5/(1-0.5))-best$coefficients[[1]])/best$coefficients[[2]],1)

sink("./Best_model.txt")
"Selected model"
summary(best)
"Prediction"
model_predict
"wt at 50% detection"
param_at_50
sink()

p <- Bosa_presence %>% 
  ggplot() +
  geom_point(aes(x = wt, y = presence))

p <- p +
  geom_line(data = model_predict, aes(x = x, y = predicted)) + 
  geom_ribbon(data = model_predict, aes(x = x, ymin = conf.low, ymax = conf.high), alpha = 0.1) +
  geom_segment(aes(x = param_at_50, y = 0, xend = param_at_50, yend = 0.5), linetype = 2, color = "grey40") +
  geom_hline(aes(yintercept = 0.5), linetype = 2, color = "grey40") +
  geom_text(aes(x = param_at_50, y = 0.55, label = param_at_50)) +
  ggtitle("Logistic regression between eDNA detection and wt") +
  xlab("Water temperature (°C)") +
  ylab("Probability of eDNA detection") +
  theme(plot.title = element_text(size = 10)) +
  scale_x_continuous(limit = c(-2, 10), breaks = seq(-2,10,2))

save_plot("./Logistic_regression_wt.pdf", p, base_height = 3.8, base_width = 5.5)

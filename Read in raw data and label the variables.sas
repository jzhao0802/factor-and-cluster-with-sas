

libname datadir "\\plyvnas01\statservices\CustomStudies\Primary Market Research\Big C\002 SAS Data";

proc import out=Data_for_Seg
datafile="\\plyvnas01\statservices\CustomStudies\Primary Market Research\Big C\001 Raw Data\Raw Data Healthy Beauty Data 2.csv"
dbms=csv replace;
Getnames=yes;
DataRow=2;
Guessingrows=250;
run;

/*
proc freq data=Data_for_Seg;
tables Q24_1-Q24_27/missing;
run;
*/


data datadir.Data_for_Seg;
set Data_for_Seg;

label  
Q24_1="01. I am always the first one who buy or own new-launched product."
Q24_2="02. I always suggest people around me to use or buy the product I use."
Q24_3="03. I don't want to try new-launched product except until someone I know suggests it because they already use it."
Q24_4="04. I always study on product information before buying it."
Q24_5="05. I don't matter the price if I really want that product."
Q24_6="06. I prefer brand name product because it indicates better epicure."
Q24_7="07. I always buy products with discounting price/giveaway."
Q24_8="08. I always buy products considering its benefits the most."
Q24_9="09. It's hard for me to decide if a product is good  until I have used it for a while."
Q24_10="10. I always buy products that are easy to buy without having to travel faraway to buy."
Q24_11="11. I like technologies that make my life more convenient."
Q24_12="12. I prefer to shop around and find products for the best price"
Q24_13="13. I am very familiar with what products should cost"
Q24_14="14. It is worth paying more for higher quality products"
Q24_15="15. If a product is not discounted I spend more time evaluating it"
Q24_16="16. Shopping convenience is more important than purchase price to me"
Q24_17="17. I go into a store looking for higher quality products"
Q24_18="18. The quality of a products is only one of several benefits I am seeking in a purchase"
Q24_19="19. If a product cost more it usually is better quality"
Q24_20="20. Higher quality products last longer"
Q24_21="21. I feel confident determining the quality of the products I buy"
Q24_22="22. Even on simple products I buy higher quality brands"
Q24_23="23. I prefer to buy trusted brands to ensure they are better products"
Q24_24="24. I prefer to buy products I am most familiar with from past experience"
Q24_25="25. I buy what people I know recommend"
Q24_26="26. If I don't fully understand how a product will perform I may still buy it"
Q24_27="27. It is risky for me to buy products I am not 100percent sure will work for me"
;

keep QNO  Q24_1-Q24_27;

run;

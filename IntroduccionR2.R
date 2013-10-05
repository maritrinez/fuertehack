# LEER DATOS

# En qué directorio vamos a trabajar (de dónde leer, escribrir)

getwd()
[1] "/Users/martinez/Documents"

setwd("~/Dropbox/IntroduccionR")


# Descargar la home de la página 

url <- "http://contributors.rubyonrails.org/"
download.file(url, destfile = "Data/contributors00.txt")

# Leer el archivo en R
contributors <- readLines("Data/contributors00.txt")
contributors[60:70]



# Ya tenemos la home guardada, ahora lo que queremos es una lista de todas las urls a las páginas
# de los contribuyentes, para descargarnoslas todas y crear un tabla con los campos: ....

# Utilizamos expresiones regulares para encontrar las url en el código de la página

contributorsLines <- grep("highlight", contributors, fixed = TRUE, value = TRUE)  # Extraemos las lineas en las que están los nombres de los contribuyentes en modo url.

r <- gregexpr("/contributors/(.*)/commits", contributorsLines)  # Obtenemos el indice en el que empieza la cadena buscada y la longitud.
contributorsURL <- regmatches(contributorsLines, r)  # Sacamos los registros
contributorsURL <- paste("http://contributors.rubyonrails.org", contributorsURL, sep="")  # Lo juntamos a la URL de la home

head(contributorsURL)





# Tenemos la lista de todas las URLs que hay que descargar, cargar en R y extraer los datos que queremos a un data.frame


contributorsdf <- data.frame()  # Se crea un data.frame vacío en el que ir guardando los datos

for (i in (1:length(contributorsURL))){  # Para cada página
	
	# Se descarga
	url2 <- contributorsURL[i]
	download.file(url2, destfile = paste("Data/contributor",i,".txt", sep = ""))
	contributor <- readLines(paste("Data/contributor",i,".txt", sep = ""))  
	
	
	# Se crea un vector con las fechas de los commits (date)
	date <- grep("commit-date", contributor, fixed = TRUE, value=TRUE)
	r <- gregexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", date)
	date <- unlist(regmatches(date,r))
	
	# Otro con los mensajes (message)
	message <- grep("commit-message", contributor, fixed = TRUE, value = TRUE)
	r <- regexec(">(.*)<", message)
	message <- regmatches(message, r)
	message <- sapply(message, function(x) x[2])
	
	# Se extra el Nombre (Name) del contribuyente y su posición en el ranking (Rank)
	r <- regexec("Rails Contributors - #(.*?) (.*) -", contributor)
	m <- unlist(regmatches(contributor, r))
	m
	Rank <- m[2]  ## MIRAR SI FUNCIONA CON MINÚSCULAS
	Name <- m[3]
	
	# Se combinan los 4 vectores y se obtienen los datos del contribuyente
	tableContributor <- as.data.frame(cbind(date, message))
	tableContributor$name <- Name
	tableContributor$rank <- Rank
	
	# Éstos se pasan al data.frame que creamos vacío y así.
	contributorsdf <- rbind(tableContributor, contributorsdf)
}


# Están los datos listos

head(contributorsdf)

# Ahora se pueden escribir
write.csv(contributorsdf, file = "Data/contributorsdf.csv", row.names = FALSE)

# Y leer
contributorsdf <- read.csv("~/Dropbox/IntroduccionR/Data/contributorsdf.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)

===================================================
	
	TRATAMIENTO Y ANÁLISIS DE DATOS

# Echar un vistazo a los datos, obtener información del objeto

str(contributorsdf)

summary(contributorsdf)


# Cambiar la clase de un objeto
contributorsdf$date <- as.Date(contributorsdf$date, "%Y-%m-%d")
summary(contributorsdf)


# Eliminar un registro
contributorsdf <- contributorsdf[which(contributorsdf$date != "1970-01-01"), ]
nrow(contributorsdf)

# Combinar con otro data.frame

ISOcountries <- read.csv("~/Dropbox/R Data/ISOcountries.csv")

head(ISOcountries)


# Asignar un país a cada contribuyente

countries <- sample(ISOcountries$codes, length(unique(contributorsdf$name)), replace = TRUE)  
# Genera un vector de igual longitud que el número de contribuyentes.

uniqueContributors <- unique(as.character(contributorsdf$name)) 
# vector con los contribuyentes

a <- data.frame(uniqueContributors, countries)  
# Juntamos ambos vectores en un data.frame

head(a)


# Se combinan los dos data.frames
contributorsdf <- merge(contributorsdf, a, by.x = "name", by.y = "uniqueContributors")  # Combina los dos data.frame por el nombre del contribuyente
str(contributorsdf)

==========================================
	CÁLCULOS

# Calcular commits por año
# Separar columna date en mes-año-día

dates <- strsplit(as.character(contributorsdf$date), "-")
contributorsdf$year <- sapply(dates, function(x) x[1])
contributorsdf$month <- sapply(dates, function(x) x[2])
rm(dates)


table(contributorsdf$year) # commits por año


mean(table(contributorsdf$year)) # media de commits por año en el periodo 2004-2013


# Commits por mes y año

table(contributorsdf$year, contributorsdf$month)


# Esto a dataframe
monthYear <- as.data.frame.matrix(table(contributorsdf$year, contributorsdf$month))

colMeans(monthYear) # media por mes (en enero, una media de 497 commits en todos los años)

rowMeans(monthYear) # media por mes por año (en 2004, una media de 32 commits por mes)


# subset los 10 con más commits
freqCommits <- data.frame(table(contributorsdf$name))	# commits por contributor
freqCommits <- freqCommits[order(-freqCommits$Freq), ]
head(freqCommits)


top10 <- as.character(freqCommits$Var1[1:10])
length(top10)


top10contributors <- contributorsdf[contributorsdf$name %in% top10, ]
str(top10contributors)


identical(sort(unique(top10contributors$name)), sort(top10))
[1] TRUE


# correlation

nCommits <- read.csv("~/Dropbox/R Data/nCommits.csv")
nCommits
plot(nCommits$contributors, nCommits$commits)
cor(nCommits$contributors, nCommits$commits)

# =======================================
# GRÁFICOS


# Pintar cada commit

plot(contributorsdf$date, factor(contributorsdf$name))


# Cambiar el aspecto
plot(contributorsdf$date, factor(contributorsdf$name), 
	 main = "Total Commits", 
	 xlab = "Date", 
	 ylab = "contributors",
	 col = rgb(0,100,0,40,maxColorValue=255),
	 pch = 18,
)
# Ver ?par



#Librería ggplot2
library(ggplot2)

p <- ggplot(top10contributors, aes(date, name))
p + geom_point()
p + geom_point(alpha = 0.2, size = 3, aes(colour = factor(name)), show_guide = FALSE) 




# Graficar commits por mes

m <- ggplot(contributorsdf, aes(month))
m + geom_bar(fill = "darkblue")




ggplot(contributorsdf, aes(month, fill=year)) + geom_bar() + coord_flip()



m <- ggplot(contributorsdf, aes(month)) +  geom_histogram(aes(fill=year))
m + facet_grid(year ~ .)



m <- ggplot(contributorsdf, aes(month, colour = year, group = year))
m+geom_freqpoly()



# Mapa
library(sp)
library(maptools)
library(RColorBrewer)

data(wrld_simpl)
commitsMap <- wrld_simpl
class(commitsMap)

# Sacamos la tabla de frecuencias por pais
countriesFreq <- as.data.frame(table(contributorsdf$countries))
head(countriesFreq)


# Lo combinamos con commitsMap@data, el data frame de datos del SpatialPolygonsDataFrame
head(commitsMap@data)


commitsMap@data <- merge(commitsMap@data, countriesFreq, by.x = "ISO2", by.y = "Var1", all.x=T)

head(commitsMap@data)


spplot(commitsMap, "Freq", col.regions = colorRampPalette(brewer.pal(9, "YlGnBu"))(17))


png(file = "Images/commits_map.png", height = 480, width = (480*2))
spplot(commitsMap, "Freq", col.regions = colorRampPalette(brewer.pal(9, "YlGnBu"))(17))
dev.off()

# Fuertehack contributors

people <- c("Fernando Guillén", "Juanjo Bazán", "Fernando Blat","Paco Guzman","Christos Zisopoulos","Alberto Perdomo")
people

peopleData <- contributorsdf[ contributorsdf$name %in% people, ]
peopleData$name

#png(file = "Images/fuertehaackCommiters.png", height = 480, width = (480*2))
p <- ggplot(peopleData, aes(date, name))
p + geom_point()
p + geom_point(alpha = 0.8, size = 3, aes(colour = factor(name)), show_guide = FALSE) 
dev.off()

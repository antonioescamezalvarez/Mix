#!/bin/bash
# -*- ENCODING: UTF-8 -*-
clear #Limpiamos la pantalla


#Guardamos la fecha actual
date=$(date +%F)

#Realizamos la peticion
precio=$(curl -s "https://apidatos.ree.es/es/datos/mercados/precios-mercados-tiempo-real?start_date=$date+T00:00&end_date=$date+T23:59&time_trunc=hour&geo_trunc=electric_system&geo_limit=peninsular&geo_ids=8741" | jq '.included[0].attributes.values[].value')

#Creamos la variable para las horas para dar formato al output
horas="
	00-01 \n
	\r01-02 \n
	\r02-03 \n
	\r03-04 \n
	\r04-05 \n
	\r05-06 \n
	\r06-07 \n
	\r07-08 \n
	\r08-09 \n
	\r09-10 \n
	\r10-11 \n
	\r11-12 \n
	\r12-13 \n
	\r13-14 \n
	\r14-15 \n
	\r15-16 \n
	\r16-17 \n
	\r17-18 \n
	\r18-19 \n
	\r19-20 \n
	\r20-21 \n
	\r21-22 \n
	\r22-23 \n
	\r23-00 \n
"

echo $precio

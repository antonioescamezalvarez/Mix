#!/bin/bash

#Theory
#Short Arguments - These are defined by a single character, prepended by a hyphen. For example, -h may denote help, -l may denote a list command.
#Long Arguments - These are whole strings, prepended by two hyphens. For example, --help denotes help, and --list denotes list.

#It is needed execute the script with ./ (this uses bash) if executes the script with sh executes sh and this one has not an array creator


#Single colon (:) - Value is required for this option
#Double colon (::) - Value is optional
#No colons - No values are required


usage () {
    echo " ./cross-section [-l <length>] [-v <voltage>] [-p <power>] [-s <security_factor>] [-d <voltage_drop_percent>] [-f <power_factor>]"
}

calculate_current_three_phase () { 
    current=$(echo "scale=2; ($power*1000.0)/($voltage*sqrt(3)*$power_factor)" | bc -l)
    current_with_factor=$(echo "scale=2; $current*$security_factor" | bc -l)
}

calculate_current_single_phase () {
    current=$(echo "scale=2; ($power*1000.0)/($voltage*$power_factor)" | bc -l)
    current_with_factor=$(echo "scale=2; $current*$security_factor" | bc -l)
}

calculate_cross_section_with_voltage_drop_criteria_three_phase () {
    #To do - Impliment coefficient k calculation (default value is 44)
    cross_section_voltage_drop_criteria=$(echo "scale=2; ($power*1000.0*$length)/(44*$voltage* ( ($voltage_drop_percent*$voltage)/(100) ) )" | bc -l)
}
calculate_cross_section_with_voltage_drop_criteria_single_phase () {
    #To do - Impliment coefficient k calculation (default value is 44)
    cross_section_voltage_drop_criteria=$(echo "scale=2; (2*$power*1000.0*$length)/(44*$voltage* ( ($voltage_drop_percent*$voltage)/(100) ) )" | bc -l)
}
calculate_cross_section_with_thermal_criteria_three_phase () {
    local iterator=0
    for c in "${current_B1_3XLPE[@]}":
    do
        #if [ $c -gt $current_with_factor ]
        if [ $(echo "scale=2; $c > $current_with_factor" | bc -l)  -eq 1 ]
        then
            cross_section_thermal_criteria=$(echo "${current_cross_section[$iterator]}")
            break
        else
            iterator=$iterator+1
        fi
    done
}
calculate_cross_section_with_thermal_criteria_single_phase () {
    local iterator=0
    for c in "${current_B1_2XLPE[@]}":
    do
        if [ $(echo "scale=2; $c > $current_with_factor" | bc -l) -eq 1 ]
        then
            cross_section_thermal_criteria=$(echo "${current_cross_section[$iterator]}")
            break
        else
            iterator=$iterator+1
        fi
    done
}
calculate_final_cross_section () {
    if [ $(echo "scale=2; $cross_section_thermal_criteria > $cross_section_voltage_drop_criteria" | bc -l) -eq 1 ]
        then
            final_cross_section=$cross_section_thermal_criteria
        else
            final_cross_section=$cross_section_voltage_drop_criteria
        fi
    local iterator=0
    for c in "${current_cross_section[@]}":
    do
        if [ $(echo "scale=2; $c == $final_cross_section" | bc -l) -eq 1 ]
        then
            if [ $monofasico -eq 0 ]
            then
                final_max_current_allowed=$(echo "${current_B1_3XLPE[$iterator]}")
                break
            else
                final_max_current_allowed=$(echo "${current_B1_2XLPE[$iterator]}")
                break
            fi
            
        else
            iterator=$iterator+1
        fi
    done
}
print_results () {
    if [ $monofasico -eq 0 ]
        then
            echo "La tensión de la línea es de 400 V"
        else
            echo "La tensión de la línea es de 230 V"
    fi
    echo "La sección del conductor es: "$final_cross_section" mm²"
    echo "La ampacidad de la línea es de: "$final_max_current_allowed" A"
    echo "La corriente real aplicando el coeficiente de seguridad de "$security_factor" es de:" "$current_with_factor" "A"
    if [ $monofasico -eq 0 ]
        then
            echo "La potencia máxima que puede transportar con un fdp de "$power_factor" es de:" "$(echo "scale=2; (sqrt(3)*$final_max_current_allowed*$voltage*$power_factor)/1000" | bc -l)" "kW"
            echo "La potencia real que transporta la línea aplicando el coeficiente de seguridad de "$security_factor" es de:" "$(echo "scale=2; (sqrt(3)*$current_with_factor*$voltage*$power_factor)/1000" | bc -l)" "kW"
            echo "La caída de tensión porcentual es de:"  $(echo "scale=2; ($power*1000.0*$length)/(44*$voltage* ( ($final_cross_section*$voltage)/(100) ) )" | bc -l | awk '{printf "%.2f\n", $0}') "%"
        else
            echo "La potencia máxima que puede transportar con un fdp de "$power_factor" es de:" "$(echo "scale=2; ($final_max_current_allowed*$voltage*$power_factor)/1000" | bc -l)" "kW"
            echo "La potencia real que transporta la línea aplicando el coeficiente de seguridad de "$security_factor" es de:" "$(echo "scale=2; ($current_with_factor*$voltage*$power_factor)/1000" | bc -l)" "kW"
            echo "La caída de tensión porcentual es de:"  $(echo "scale=2; (2*$power*1000.0*$length)/(44*$voltage* ( ($final_cross_section*$voltage)/(100) ) )" | bc -l | awk '{printf "%.2f\n", $0}') "%"
    fi
     
    
    
}


length=0.0
voltage=0.0
power=0.0
power_factor=0.8
current=0.0
current_with_factor=0.0
security_factor=1.25
voltage_drop_percent=1.5
monofasico=0
cross_section_voltage_drop_criteria=0.0
cross_section_thermal_criteria=0.0
current_B1_3XLPE=(17.5 24 32 41 57 77 100 124 151 193 234 272 313 356 419)
current_B1_2XLPE=(20 28 38 49 68 91 115 143 174 223 271 314 359 409 489)
current_cross_section=(1.5 2.5 4 6 10 16 25 35 50 70 95 120 150 185 240)
final_cross_section=0.0
final_max_current_allowed=0.0

while getopts l:v:p:hs::d::f:: parm ; do
    case $parm in
        l)
            
            length=$OPTARG
            ;;

        v)
            voltage=$OPTARG
            ;;

        p)
            power=$OPTARG
            ;;
        s)
            security_factor=$OPTARG
            ;;
        d)
            voltage_drop_percent=$OPTARG
            ;;
        f)
            power_factor=$OPTARG
            ;;
        h | *)
            usage
            exit 0
    esac
done

#First step is check if the line is SINGLE-PHASE or THREE-PHASE
if [ $voltage -eq 230 ]
then
    monofasico=1
else
    monofasico=0
fi

if [ $monofasico -eq 1 ]
then
    #Calculate the line as SINGLE-PHASE
    calculate_current_single_phase
    calculate_cross_section_with_voltage_drop_criteria_single_phase
    calculate_cross_section_with_thermal_criteria_single_phase
    calculate_final_cross_section
    
    
else
    #Calculate the line as THREE-PHASE
    calculate_current_three_phase
    calculate_cross_section_with_voltage_drop_criteria_three_phase
    calculate_cross_section_with_thermal_criteria_three_phase
    calculate_final_cross_section
    
fi
print_results




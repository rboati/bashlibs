
declare -gA __NS__TEXT_ATTRS=(
	[normal]='21;22;23;24;25;26;27;28:29'
	[bold]=1
	[dim]=2
	[italic]=3
	[underline]=4
	[underline2]=21
	[blink]=5
	[blink2]=6
	[reverse]=7
	[hidden]=8
	[strike]=9
)
declare -gA __NS__TEXT_ATTRS_UNSET=(
	[normal]='21;22;23;24;25;26;27;28:29'
	[bold]=22
	[dim]=22
	[italic]=23
	[underline]=24
	[underline2]=24
	[blink]=25
	[blink2]=25
	[reverse]=27
	[hidden]=28
	[strike]=29
)
declare -gA __NS__FGCOLORS16=(
	[black]=30
	[red]=31
	[green]=32
	[yellow]=33
	[blue]=34
	[magenta]=35
	[cyan]=36
	[lightgray]=37
	[darkgray]=90
	[lightred]=91
	[lightgreen]=92
	[lightyellow]=93
	[lightblue]=94
	[lightmagenta]=95
	[lightcyan]=96
	[white]=97
)
declare -gA __NS__BGCOLORS16=(
	[black]=40
	[red]=41
	[green]=42
	[yellow]=43
	[blue]=44
	[magenta]=45
	[cyan]=46
	[lightgray]=47
	[darkgray]=100
	[lightred]=101
	[lightgreen]=102
	[lightyellow]=103
	[lightblue]=104
	[lightmagenta]=105
	[lightcyan]=106
	[white]=107
)
declare -gA __NS__COLORS256=(
	[black]=0
	[red]=1
	[green]=2
	[yellow]=3
	[blue]=4
	[magenta]=5
	[cyan]=6
	[lightgray]=7
	[darkgray]=8
	[lightred]=9
	[lightgreen]=10
	[lightyellow]=11
	[lightblue]=12
	[lightmagenta]=13
	[lightcyan]=14
	[white]=15
)
declare -gA __NS__COLORS16M=(
	[black]='0;0;0'
	[red]='255;0;0'
	[green]='0;255;0'
	[yellow]='255;255;0'
	[blue]='0;0;255'
	[magenta]='255;0;255'
	[cyan]='0;255;255'
	[lightgray]='170;170;170'
	[darkgray]='85;85;85'
	[lightred]='255;128;128'
	[lightgreen]='128;255;128'
	[lightyellow]='255;255;85'
	[lightblue]='0;170;255'
	[lightmagenta]='255;128;255'
	[lightcyan]='128;255;255'
	[white]='255;255;255'
)

__NS__convert_rgb_to_palette256() {
	declare -i r=$(( $1 / 51 ))
	declare -i g=$(( $2 / 51 ))
	declare -i b=$(( $3 / 51 ))
	printf '%d' $(( 16 + r * 36 + g * 6 + b ))
}

__NS__convert_palette_to_rgb256() {
	declare -i color=$(( $1 % 256 ))
	if (( i < 16 )); then
		return '0;0;0'
	elif (( i > 231 )); then
		return '255;255;255'
	fi
    declare -i r=$(( (color-16) / 36 ))
    declare -i g=$(( ( (color-16) % 36) / 6 ))
    declare -i b=$(( (color-16) % 6 ))
	printf '%d;%d;%d' $r $g $b
}

__NS__set_text_attr() {
	declare ansi='' arg attr code
	declare -a attrs
	for arg in "$@"; do
		IFS=':;, ' attrs=( $arg )
		for attr in "${attrs[@]}"; do
			code="${__NS__TEXT_ATTRS[$attr]}"
			[[ -n $code ]] && ansi+="$code;"
		done
	done
	[[ -n $ansi ]] && printf '%b' "\e[${ansi%;}m"
}

__NS__unset_text_attr() {
	declare ansi='' arg attr code
	declare -a attrs
	for arg in "$@"; do
		IFS=':;, ' attrs=( $arg )
		for attr in "${attrs[@]}"; do
			code="${__NS__TEXT_ATTRS_UNSET[$attr]}"
			[[ -n $code ]] && ansi+="$code;"
		done
	done
	[[ -n $ansi ]] && printf '%b' "\e[${ansi%;}m"
}

__NS__set_color16() {
	declare FG="$1"
	declare BG="$2"
	declare ansi='' color arg attr code
	declare -a attrs
	shift 2
	if [[ -n $FG ]]; then
		color="${__NS__FGCOLORS16[$FG]}"
		if [[ -n $color ]]; then
			ansi+="$color;"
		else
			(( (FG >= 30 && FG <= 37) || (FG >= 90 && FG <= 97) )) && ansi+="$FG;"
		fi
	fi
	if [[ -n $BG ]]; then
		color="${__NS__BGCOLORS16[$BG]}"
		if [[ -n $color ]]; then
			ansi+="$color;"
		else
			(( (BG >= 40 && BG <= 47) || (BG >= 100 && BG <= 107) )) && ansi+="$BG;"
		fi
	fi
	for arg in "$@"; do
		IFS=':;, ' attrs=( $arg )
		for attr in "${attrs[@]}"; do
			code="${__NS__TEXT_ATTRS[$attr]}"
			[[ -n $code ]] && ansi+="$code;"
		done
	done
	[[ -n $ansi ]] && printf '%b' "\e[${ansi%;}m"
}

__NS__set_color256() {
	declare FG="$1"
	declare BG="$2"
	declare ansi='' arg attr code
	declare -a attrs
	shift 2
	if [[ -n $FG ]]; then
		ansi+='38;5;'
		color="${__NS__COLORS256[$FG]}"
		if [[ -n $color ]]; then
			ansi+="$color;"
		else
			ansi+="$(( FG % 256 ));"
		fi
	fi
	if [[ -n $BG ]]; then
		ansi+='48;5;'
		color="${__NS__COLORS256[$BG]}"
		if [[ -n $color ]]; then
			ansi+="$color;"
		else
			ansi+="$(( BG % 256 ));"
		fi
	fi
	for arg in "$@"; do
		IFS=':;, ' attrs=( $arg )
		for attr in "${attrs[@]}"; do
			code="${__NS__TEXT_ATTRS[$attr]}"
			[[ -n $code ]] && ansi+="$code;"
		done
	done
	[[ -n $ansi ]] && printf '%b' "\e[${ansi%;}m"
}

__NS__set_color16m() {
	declare FG="$1"
	declare BG="$2"
	declare ansi='' arg attr code
	declare -i i j
	declare -a rgb attrs
	shift 2
	IFS=':;, ' rgb=( $FG )
	if (( ${#rgb[@]} == 3 )); then
		ansi+="38;2;"
		for i in "${rgb[@]}"; do
			ansi+="$(( i % 256 ));"
		done
	fi
	IFS=':;, ' rgb=( $BG )
	if (( ${#rgb[@]} == 3 )); then
		ansi+="48;2;"
		for i in "${rgb[@]}"; do
			ansi+="$(( i % 256 ));"
		done
	fi
	for arg in "$@"; do
		IFS=':;, ' attrs=( $arg )
		for attr in "${attrs[@]}"; do
			code="${__NS__TEXT_ATTRS[$attr]}"
			[[ -n $code ]] && ansi+="$code;"
		done
	done
	[[ -n $ansi ]] && printf '%b' "\e[${ansi%;}m"
}

__NS__unset_color() {
	declare FG="$1"
	declare BG="$2"
	declare ansi='' arg attr code
	declare -a attrs
	shift 2
	[[ -n $FG ]] && ansi+="39;"
	[[ -n $BG ]] && ansi+="49;"
	for arg in "$@"; do
		IFS=':;, ' attrs=( $arg )
		for attr in "${attrs[@]}"; do
			code="${__NS__TEXT_ATTRS_UNSET[$attr]}"
			[[ -n $code ]] && ansi+="$code;"
		done
	done
	if [[ -n $ansi ]]; then
		printf '%b' "\e[${ansi%;}m"
	else
		printf '%b' "\e[0m"
	fi
}

__NS__printf16() {
	__NS__set_color16 "$__NS__FG" "$__NS__BG" "$__NS__ATTR"
	printf "$@"
	__NS__unset_color "$__NS__FG" "$__NS__BG" "$__NS__ATTR"
}

__NS__printf256() {
	__NS__set_color256 "$__NS__FG" "$__NS__BG" "$__NS__ATTR"
	printf "$@"
	__NS__unset_color "$__NS__FG" "$__NS__BG" "$__NS__ATTR"
}

__NS__printf16m() {
	__NS__set_color16m "$__NS__FG" "$__NS__BG" "$__NS__ATTR"
	printf "$@"
	__NS__unset_color "$__NS__FG" "$__NS__BG" "$__NS__ATTR"
}

__NS__contrast_color16() {
	declare -i color="$(( $1 % 16 ))"
	if (( color == 0 || color == 8 )); then
		printf 15
	else
		printf 0
	fi
}

# Return a color that contrasts with the given color
# Bash only does integer division, so keep it integral
__NS__contrast_color256() {
	declare -i color=$(( $1 % 256 ))
    declare -i r g b luminance

    if (( color < 16 )); then # Initial 16 ANSI colors
		__NS__contrast_color16 $color
        return
    fi

    # Greyscale # rgb_R = rgb_G = rgb_B = (number - 232) * 10 + 8
    if (( color > 231 )); then # Greyscale ramp
        if (( color < 244 )); then
			printf 15
		else
			printf 0
		fi
        return
    fi

    # All other colors:
    # 6x6x6 color cube = 16 + 36*R + 6*G + B  # Where RGB are [0..5]
    # See http://stackoverflow.com/a/27165165/5353461

    r=$(( (color - 16) / 36 ))
    g=$(( ( (color - 16) % 36 ) / 6 ))
    b=$(( (color - 16) % 6 ))

    # If luminance is bright, print number in black, white otherwise.
    # Green contributes 587/1000 to human perceived luminance - ITU R-REC-BT.601
	#if (( g > 2)); then
	#	printf 0
	#else
	#	printf 15
	#fi
    #return

    # Uncomment the below for more precise luminance calculations

    # Calculate percieved brightness
    # See https://www.w3.org/TR/AERT#color-contrast
    # and http://www.itu.int/rec/R-REC-BT.601
    # Luminance is in range 0..5000 as each value is 0..5
    luminance=$(( (r * 299) + (g * 587) + (b * 114) ))
    if (( luminance > 2500 )); then
		printf 0
	else
		printf 15
	fi
}

__NS__contrast_color16m() {
	declare -i r=$(( $1 % 256 ))
	declare -i g=$(( $2 % 256 ))
	declare -i b=$(( $3 % 256 ))
	declare -i luminance=$(( (r * 299) + (g * 587) + (b * 114) ))
    if (( luminance > 127500 )); then
		printf '0;0;0'
	else
		printf '255;255;255'
	fi
}

__NS__save_cursor_pos() {
	printf '%b' "\e[s"
}

__NS__restore_cursor_pos() {
	printf '%b' "\e[u"
}

__NS__set_cursor_pos() {
	declare -i LINE="$1"
	declare -i COL="$2"
	printf '%b' "\e[${LINE};${COL}H"
}

__NS__set_cursor_up() {
	declare -i LINES="$1"
	printf '%b' "\e[${LINES}A"
}

__NS__set_cursor_down() {
	declare -i LINES="$1"
	printf '%b' "\e[${LINES}B"
}

__NS__set_cursor_right() {
	declare -i COLS="$1"
	printf '%b' "\e[${COLS}C"
}

__NS__set_cursor_left() {
	declare -i COLS="$1"
	printf '%b' "\e[${COLS}D"
}

__NS__clear_screen() {
	printf '%b' "\e[2J"
}

__NS__erase_to_EOL() {
	printf '%b' "\e[K"
}


__NS__image16m() {
	declare FILE="$1"
	declare GEOMETRY="$2"
	declare -a upper=() lower=()
	declare -i i=0 prev_col='-1' columns
	declare rgb
	declare col row alpha red green blue X

	convert -thumbnail "$GEOMETRY" -define txt:compliance=SVG "$FILE" txt:- | {
		while IFS=',:() ' read col row alpha red green blue X; do
			if [[ $col == "#" ]]; then
				continue
			fi
			rgb="${red};${green};${blue}"
			if (( row == 0 )); then
				prev_col=col
				upper[$col]="$rgb"
			else
				columns=prev_col
				lower[$col]="$rgb"
				break
			fi
		done
		while IFS=',:() ' read col row alpha red green blue X; do
			rgb="${red};${green};${blue}"
			if (( (row % 2) == 0 )); then
				upper[$col]="$rgb"
			else
				lower[$col]="$rgb"
				if (( col == (columns - 1) )); then
					for (( i=0; i < columns; ++i )); do
						printf '%b' "\e[38;2;${upper[$i]};48;2;${lower[$i]}m▀"
					done
					printf '%b' "\e[0m\e[K\e[s\n\e[u\e[${columns}D\e[1B"
					upper=()
				fi
			fi
		done

		if [[ -n ${upper[0]} ]]; then
			for (( i=0; i < columns; ++i )); do
				printf '%b' "\e[38;2;${upper[$i]}m▀"
			done
			echo -e "\e[0m\e[K"
		fi
	}
}

__NS__image256() {
	declare FILE="$1"
	declare GEOMETRY="$2"
	declare -a upper=() lower=()
	declare -i i=0 prev_col='-1' columns
	declare -i color
	declare col row alpha red green blue X

	convert -thumbnail "$GEOMETRY" -define txt:compliance=SVG "$FILE" txt:- | {
		while IFS=',:() ' read col row alpha red green blue X; do
			if [[ $col == "#" ]]; then
				continue
			fi
			color="$(__NS__convert_rgb_to_palette256 ${red} ${green} ${blue})"
			if (( row == 0 )); then
				prev_col=col
				upper[$col]="$color"
			else
				columns=prev_col
				lower[$col]="$color"
				break
			fi
		done
		while IFS=',:() ' read col row alpha red green blue X; do
			color="$(__NS__convert_rgb_to_palette256 ${red} ${green} ${blue})"
			if (( (row % 2) == 0 )); then
				upper[$col]="$color"
			else
				lower[$col]="$color"
				if (( col == (columns - 1) )); then
					for (( i=0; i < columns; ++i )); do
						printf '%b' "\e[38;5;${upper[$i]};48;5;${lower[$i]}m▀"
					done
					printf '%b' "\e[0m\e[K\e[s\n\e[u\e[${columns}D\e[1B"
					upper=()
				fi
			fi
		done

		if [[ -n ${upper[0]} ]]; then
			for (( i=0; i < columns; ++i )); do
				printf '%b' "\e[38;5;${upper[$i]}m▀"
			done
			echo -e "\e[0m\e[K"
		fi
	}
}

__NS__demo_text_attributes() {
	declare -a attrs=( normal bold dim italic underline underline2 blink blink2 reverse hidden strike )
	declare attr
	declare -i i
	for (( i=0; i < ${#attrs[@]}; ++i )); do
		attr=${attrs[$i]}
		printf '['
		__NS__set_text_attr $attr
		printf '%s' $attr
		__NS__unset_text_attr $attr
		printf '] '
	done
	echo
}

__NS__demo_color256() {
	declare -i i c
	for i in {0..15}; do
		FG=$(__NS__contrast_color256 $i) BG=$i __NS__printf256 ' %3d ' $i
	done
	__NS__unset_color
	echo

	#let i=16
	#for c in {1..216}; do
	#	FG=$(__NS__contrast_color256 $i) BG=$i __NS__printf256 ' %3d ' $i
	#	if (( (c % 108) == 0 )); then
	#		let i=i+1
   	#	 	__NS__unset_color
	#		echo
	#	elif (( (c % 18) == 0 )); then
	#		let i=i-71
   	#	 	__NS__unset_color
	#		echo
	#	elif (( (c % 6) == 0 )); then
	#		let i=i+31
	#	else
	#		let i=i+1
	#	fi
	#done

	#let i=16
	#for c in {1..216}; do
	#	FG=$(__NS__contrast_color256 $i) BG=$i __NS__printf256 ' %3d ' $i
	#	if (( (c % 36) == 0 )); then
	#		let i=i-179
   	#	 	__NS__unset_color
	#		echo
	#	elif (( (c % 18) == 0 )); then
	#		let i=i+31
	#	elif (( (c % 6) == 0 )); then
	#		let i=i+31
	#	else
	#		let i=i+1
	#	fi
	#done

	let i=16
	for c in {1..216}; do
		FG=$(__NS__contrast_color256 $i) BG=$i __NS__printf256 ' %3d ' $i
		if (( (c % 108) == 0 )); then
			let i=i-179
   		 	__NS__unset_color
			echo
		elif (( (c % 18) == 0 )); then
			let i=i+19
   		 	__NS__unset_color
			echo
		else
			let i=i+1
		fi
	done

	#for i in {16..231}; do
	#	FG=$(__NS__contrast_color256 $i) BG=$i __NS__printf256 ' %3d ' $i
	#	if (( ( (i-15) % 36) == 0 )); then
   	#	 	__NS__unset_color
	#		echo
	#	fi
	#done

	for i in {232..255}; do
		FG=$(__NS__contrast_color256 $i) BG=$i __NS__printf256 ' %3d ' $i
	done
	__NS__unset_color
	echo
}

__NS__demo_color16m() {
	declare -i i
	declare BGCOLOR
	for i in {0..255}; do
		BG="$i,0,0" __NS__printf16m ' '
	done
	__NS__unset_color
	echo

	for i in {0..255}; do
		BG="0,$i,0" __NS__printf16m ' '
	done
	__NS__unset_color
	echo

	for i in {0..255}; do
		BG="0,0,$i" __NS__printf16m ' '
	done
	__NS__unset_color
	echo

	for i in {0..255}; do
		let h=$i/43
		let f=$i-43*h
		let t=f*255/43
		let q=255-t

		if   (( h == 0 )); then BGCOLOR="255,$t,0"
		elif (( h == 1 )); then BGCOLOR="$q,255,0"
		elif (( h == 2 )); then BGCOLOR="0,255,$t"
		elif (( h == 3 )); then BGCOLOR="0,$q,255"
		elif (( h == 4 )); then BGCOLOR="$t,0,255"
		elif (( h == 5 )); then BGCOLOR="255,0,$q"
		else                    BGCOLOR="0,0,0"
		fi
		BG="$BGCOLOR" __NS__printf16m ' '
	done
	__NS__unset_color
	echo
}





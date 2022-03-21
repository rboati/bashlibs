
# Dependencies:
# libimport.bash
# libcolor.bash
# convert (imagemagik)

# shellcheck disable=SC1090
source "$__DIR__/libimport.bash"
bash_import ./libcolor.bash=__NS__

__NS__image16m() {
	declare FILE="$1"
	declare GEOMETRY="$2"
	declare -a upper=() lower=()
	declare -i i=0 prev_col='-1' columns
	declare rgb
	declare col row alpha red green blue X

	convert -thumbnail "$GEOMETRY" -define txt:compliance=SVG "$FILE" txt:- | {
		while IFS=',:() ' read -r col row alpha red green blue X; do
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
		while IFS=',:() ' read -r col row alpha red green blue X; do
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
		while IFS=',:() ' read -r col row alpha red green blue X; do
			if [[ $col == "#" ]]; then
				continue
			fi
			color="$(__NS__convert_rgb_to_palette256 ${red} ${green} ${blue})"
			if (( row == 0 )); then
				# shellcheck disable=2034
				prev_col=col
				upper[$col]="$color"
			else
				columns=prev_col
				lower[$col]="$color"
				break
			fi
		done
		# shellcheck disable=SC2034
		while IFS=',:() ' read -r col row alpha red green blue X; do
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


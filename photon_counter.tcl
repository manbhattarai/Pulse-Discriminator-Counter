# ============================================
# Project Creator with Virtual Drive Mapping
# ============================================

# Get the real script directory (long path)
set script_dir [file dirname [file normalize [info script]]]
set proj_name "photon_counter"
set part "xc7z010clg400-1"

puts "=========================================="
puts "Original path: $script_dir"
puts "=========================================="

# Create virtual drive mapping to shorten path
# Map V: to your long path
set long_path [file nativename $script_dir]
puts "Mapping virtual drive V: to $long_path"

# Execute subst command (Windows only)
if {$::tcl_platform(platform) == "windows"} {
    catch {exec subst V: /D} ;# Remove existing mapping if any
    exec subst V: $long_path
    puts "✓ Virtual drive V: created"
    
    # Use the virtual drive for project
    set build_dir "V:/build"
    file mkdir $build_dir
    
} else {
    puts "WARNING: Not on Windows, using original path"
    set build_dir "${script_dir}/build"
    file mkdir $build_dir
}

puts "Project will be created at: $build_dir"
puts "=========================================="

# Create project using short virtual path
create_project ${proj_name} ${build_dir}/${proj_name} -part ${part} -force


# Add RTL files (from source directory)
set rtl_files [list \
 "${script_dir}/src/adc_clk_gen.v" \
 "${script_dir}/src/adc_interface.v" \
 "${script_dir}/src/bin_gen_alternate.v" \
 "${script_dir}/src/counter_case_alternate.v" \
 "${script_dir}/src/counter_dac_out.v" \
 "${script_dir}/src/discriminator_FIFO.v" \
 "${script_dir}/src/myfifo.v" \
]

foreach rtl_file $rtl_files {
    if {[file exists $rtl_file]} {
        add_files -fileset sources_1 $rtl_file
    } else {
        puts "WARNING: File not found: $rtl_file"
    }
}

# Set all Verilog files to relative paths
set_property PATH_MODE RelativeOnly [get_files *.v]

# Add constraints
set xdc_file "${script_dir}/constrs/pins.xdc"
if {[file exists $xdc_file]} {
    add_files -fileset constrs_1 $xdc_file
}

# Add memory files (if they exist)
set mem_files [glob -nocomplain ${script_dir}/mem_files/*.mem]
if {[llength $mem_files] > 0} {
    add_files -fileset sources_1 $mem_files
    set_property file_type "Memory File" [get_files "*.mem"]
}

# Create block design
set bd_tcl "${script_dir}/bd/block_design.tcl"
if {[file exists $bd_tcl]} {
    puts "Creating block design from: $bd_tcl"
    source $bd_tcl
    
    # Generate wrapper
    set bd_file [get_files -filter {FILE_TYPE == "Block Designs"}]
    if {$bd_file ne ""} {
        make_wrapper -files $bd_file -top -import
        set wrapper_name [file rootname [file tail [get_files *_wrapper.v]]]
        set_property top $wrapper_name [get_filesets sources_1]
        puts "Top module set to: $wrapper_name"
    }
} else {
    puts "WARNING: Block design not found: $bd_tcl"
}

# Create synthesis run
if {[get_runs -quiet synth_1] eq ""} {
    create_run -name synth_1 -flow {Vivado Synthesis 2020} -constrset constrs_1
}
current_run -synthesis [get_runs synth_1]

# Create implementation run
if {[get_runs -quiet impl_1] eq ""} {
    create_run -name impl_1 -flow {Vivado Implementation 2020} -constrset constrs_1 -parent_run synth_1
}
current_run -implementation [get_runs impl_1]

puts "=========================================="
puts "✓ Project created successfully!"
puts "  Location: ${build_dir}/${proj_name}"
puts "  Open with: vivado ${build_dir}/${proj_name}/${proj_name}.xpr"
puts "=========================================="
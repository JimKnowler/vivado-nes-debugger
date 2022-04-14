# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
namespace eval ::optrace {
  variable script "C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.runs/synth_1/top.tcl"
  variable category "vivado_synth"
}

# Try to connect to running dispatch if we haven't done so already.
# This code assumes that the Tcl interpreter is not using threads,
# since the ::dispatch::connected variable isn't mutex protected.
if {![info exists ::dispatch::connected]} {
  namespace eval ::dispatch {
    variable connected false
    if {[llength [array get env XILINX_CD_CONNECT_ID]] > 0} {
      set result "true"
      if {[catch {
        if {[lsearch -exact [package names] DispatchTcl] < 0} {
          set result [load librdi_cd_clienttcl[info sharedlibextension]] 
        }
        if {$result eq "false"} {
          puts "WARNING: Could not load dispatch client library"
        }
        set connect_id [ ::dispatch::init_client -mode EXISTING_SERVER ]
        if { $connect_id eq "" } {
          puts "WARNING: Could not initialize dispatch client"
        } else {
          puts "INFO: Dispatch client connection id - $connect_id"
          set connected true
        }
      } catch_res]} {
        puts "WARNING: failed to connect to dispatch server - $catch_res"
      }
    }
  }
}
if {$::dispatch::connected} {
  # Remove the dummy proc if it exists.
  if { [expr {[llength [info procs ::OPTRACE]] > 0}] } {
    rename ::OPTRACE ""
  }
  proc ::OPTRACE { task action {tags {} } } {
    ::vitis_log::op_trace "$task" $action -tags $tags -script $::optrace::script -category $::optrace::category
  }
  # dispatch is generic. We specifically want to attach logging.
  ::vitis_log::connect_client
} else {
  # Add dummy proc if it doesn't exist.
  if { [expr {[llength [info procs ::OPTRACE]] == 0}] } {
    proc ::OPTRACE {{arg1 \"\" } {arg2 \"\"} {arg3 \"\" } {arg4 \"\"} {arg5 \"\" } {arg6 \"\"}} {
        # Do nothing
    }
  }
}

proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
OPTRACE "synth_1" START { ROLLUP_AUTO }
set_param chipscope.maxJobs 4
set_msg_config -id {Synth 8-256} -limit 10000
set_msg_config -id {Synth 8-638} -limit 10000
OPTRACE "Creating in-memory project" START { }
create_project -in_memory -part xc7a100tcsg324-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.cache/wt [current_project]
set_property parent.project_path C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.xpr [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property board_part digilentinc.com:arty-a7-100:part0:1.0 [current_project]
set_property ip_output_repo c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
OPTRACE "Creating in-memory project" END { }
OPTRACE "Adding files" START { }
read_verilog -library xil_defaultlib -sv {
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/ALU.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/ALUFullAdder.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/AddressBusRegister.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/Background.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/nes/CPUMemoryMap.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/nes/ClockEnable.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/nes/Cpu2A03.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/Cpu6502.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/DL.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/DOR.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/Decoder.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-nes/hardware/FIFO.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/IR.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-common/hardware/Memory.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/nes/NES.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-nes/NESDebugger.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-nes/NESDebuggerMCU.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-nes/NESDebuggerTop.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-nes/NESDebuggerValues.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/PCH.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/PCL.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPU.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUAttributeAddress.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUChipEnable.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUIncrementX.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUIncrementY.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/nes/PPUMemoryMap.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUPatternTableAddress.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUSprite8x8TileAddress.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PPUTileAddress.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/PaletteLookupRGB.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/ProcessorStatus.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/Register.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/Routing.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-common/SPIPeripheral.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/Shift16.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/Shift8.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/ShiftParallelLoad8.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/SpriteRasterizerPriority.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/Sprites.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/cpu6502/TCU.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/nes/VideoOutput.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/new/top.v
}
read_verilog -library xil_defaultlib {
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-nes/NESProfiler.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/debugger-common/Sync.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/vga/VGAGenerator.v
  C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/imports/nes/ppu/vga/VGAOutput.v
}
read_ip -quiet C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_board.xdc]
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc]
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_ooc.xdc]

read_ip -quiet C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0_ooc.xdc]

read_ip -quiet C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xdc]
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0_clocks.xdc]
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0_ooc.xdc]

read_ip -quiet C:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/NESProfilerMemory/NESProfilerMemory.xci
set_property used_in_implementation false [get_files -all c:/Users/jim/Documents/GitHub/personal/vivado/vivado-nes-debugger/vivado-nes-debugger.srcs/sources_1/ip/NESProfilerMemory/NESProfilerMemory_ooc.xdc]

OPTRACE "Adding files" END { }
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc C:/Users/jim/Documents/GitHub/personal/digilent-xdc/Arty-A7-100-Master.xdc
set_property used_in_implementation false [get_files C:/Users/jim/Documents/GitHub/personal/digilent-xdc/Arty-A7-100-Master.xdc]

read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

OPTRACE "synth_design" START { }
synth_design -top top -part xc7a100tcsg324-1
OPTRACE "synth_design" END { }


OPTRACE "write_checkpoint" START { CHECKPOINT }
# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef top.dcp
OPTRACE "write_checkpoint" END { }
OPTRACE "synth reports" START { REPORT }
create_report "synth_1_synth_report_utilization_0" "report_utilization -file top_utilization_synth.rpt -pb top_utilization_synth.pb"
OPTRACE "synth reports" END { }
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
OPTRACE "synth_1" END { }

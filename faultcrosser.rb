#!/usr/bin/env ruby

require_relative "src/fault_tree.rb"
require_relative "src/robust_vistor"
require_relative "src/fault_model"
require_relative "src/fault_config"

# frozen_string_literal: true

# TLA-Robust -- a script for calculating robustness of TLA+ models.
# Given:
# -- A newline-separated list of fault action names
# -- A composed model
# -- A newline-separated list of safety property (invariant) names to evaluate against.
# TLA-Robust will compute the maximum robustness with respect to the named faults.

# ***** HELPER FNS ***** #
def usage
  puts "USAGE:"
  puts "tla-robust [path to model] [path to file with invariants] [faults]"
end


# ***** PARSE ARGS ***** #

if ARGV.length != 3
  usage
  exit 1
end

model_path = ARGV[0]
invs_path = ARGV[1]
faults = ARGV[2]


# ***** CONFIGURE FILES ***** #

data_dir = "fault-data"
Dir.mkdir data_dir unless File.exist? "fault-data"

# ----- prepare config file for user supplied invariants

cfg_path = "#{data_dir}/fault-model.cfg"
fault_config = FaultConfig.new(invs_path, cfg_path)


# ----- prepare fault-centered TLA+ model for model checking.

model_name = "RobustModel"
fault_model_path = "#{data_dir}/#{model_name}.tla"

lines = File.readlines model_path
# Must be at least two lines in a valid TLA+ model.
# The MODULE declaration and terminating ====
unless lines.length > 1
  puts "Error: invalid TLA+ model."
  exit 1
end

# Configure model to share modelname
lines[0] = "---- MODULE #{model_name} ----\n"

File.open(fault_model_path, "w") { | f | f.write lines.join }

# Now, prepare fault_model object to abstract over files.
fault_model = FaultModel.new(fault_model_path)


# ***** MODEL CHECKING ***** #

# # First: sanity check, ensure the model works in the normative environment.
#
# unless system "tlc", fault_model_path, "-config", fault_model_cfg

# Traverse the lattice of faults
# Finding the maximally sized robust ones
lattice = FaultTree.new(faults)
visitor = RobustVisitor.new(fault_model, fault_config)

lattice.traverse(visitor)

# Formatted output
print "Robustness: "
visitor.robustness.each {| set | print "{ " << set.join(", ") << " }, "}
puts

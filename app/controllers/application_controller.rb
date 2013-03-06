class ApplicationController < ActionController::Base
  protect_from_forgery

  public

  def profile_object_manifest(custom_object_name)
    '<?xml version="1.0" encoding="UTF-8"?>
        <Package xmlns="http://soap.sforce.com/2006/04/metadata">
            <types>
                <members>' + custom_object_name + '</members>
                <name>CustomTab</name>
            </types>
            <types>
                <members>' + custom_object_name + '</members>
                <name>CustomObject</name>
            </types>
            <types>
              <members>*</members>
              <name>Profile</name>
            </types>
            <version>26.0</version>
        </Package>'
  end

  def file_profile_path
    session["username"] + "/profiles/"
  end

  def file_object_path
    session["username"] + "/objects/"
  end
end

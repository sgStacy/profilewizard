# ProfileController
#
# Author::    Stacy Crochet
# Copyright:: Copyright (c) 2013
# License::   Distributes under the same terms as Ruby

# Contains controller methods to download, modify, and deploy profiles

require 'metaforce'
require 'zip/zip'
require 'jquery-rails'
require 'fog'
class ProfileController < ApplicationController

  # Display the profiles and the object permission changes to make
  def index

    # Set the Metaforce configuration
    Metaforce.configure do |config|

      config.username = session["username"]
      config.password = session["password"]
      config.security_token = session["security_token"]
      config.host = session["host"]
    end

    Metaforce.configuration.log = false

    client = Metaforce.new :username => session["username"],
                           :password => session["password"],
                           :security_token => session["security_token"],
                           :host => session["host"]

    # Custom Objects
    @custom_objects = client.list_metadata('CustomObject').collect { |t| t.full_name }

    # Profiles
    @profiles = client.list_metadata('Profile').collect { |t| t.full_name }

    #Display the template
    respond_to do |format|
      format.html
      format.js
    end

  end

  # Display the login form
  def login
    respond_to do |format|
      format.html
      format.js
    end
  end

  # Authenticate the login
  def authenticate

    print "authenticate"

    # Set the session variables
    session["username"] = params[:username]
    session["password"] = params[:password]
    session["security_token"] = params[:security_token]

    (params[:host] == "Sandbox") ? session["host"] = "test.salesforce.com" : session["host"] = "login.salesforce.com"

    # Redirect to the index page
    respond_to do |format|
      format.html {redirect_to action: "index"}
      format.js
      #format.html
      #format.json
    end

  end

  # Used to update and deploy files
  def update_files


    Metaforce.configure do |config|

      config.username = session["username"]
      config.password = session["password"]
      config.security_token = session["security_token"]
      config.host = session["host"]
    end

    Metaforce.configuration.log = false

    client = Metaforce.new :username => session["username"],
                           :password => session["password"],
                           :security_token => session["security_token"],
                           :host => session["host"]

    # Custom Objects
    @custom_objects = client.list_metadata('CustomObject').collect { |t| t.full_name }

    # Profiles
    @profiles = client.list_metadata('Profile').collect { |t| t.full_name }
    @profiles = @profiles.sort! { |a,b| a <=> b }


    if(params["deploy"] != "Deploy" and params["download"] != "Download Files")

      # Download the files and display the results

      @custom_object = nil

      if(params[:custom_objects] != nil)


        @custom_object = params[:custom_objects]

        # load the files
        load_files(client, params[:custom_objects])

        files = Dir.glob(session["username"] + '/profiles/*')

        # Load the files in a Hash
        @file_hash = Hash.new

        files.each do |profile_filename|

            f = File.open(profile_filename, "r")

            file_contents = f.read

            @file_hash[profile_filename] = file_contents

            f.close
        end

        # Save the object file
        f = File.open('./' + file_object_path + @custom_object + ".object", "r")

        @file_hash[@custom_object + ".object"] = f.read

        f.close


=begin
          connection = Fog::Storage.new({
                                            provider: 'AWS',
                                            aws_access_key_id: 'AKIAJ3KTLH5K75R2XTCQ',
                                            aws_secret_access_key: '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'
                                        })


        # Create the Array
         profileArr = Array.new
=end

        # Get the profiles and add them to the array

   # @profiles.each do |profile|
   #   profileArr.push(profile)
   # end

        # First, a place to contain the glorious details
=begin
        directory = connection.directories.get(
            'profilesrc'
        )

        @profiles.each do |profile|

          f = File.open('./' + session["username"] + '/profiles/' + profile + '.profile', "r")

          directory.files.create(:key => session["username"] + profile + '.profile',
                                 :body => f,
                                 :public => false)

          f.close

        end
=end

        # Delete the folder
        FileUtils.rm_rf('./' + session["username"])

      end

    elsif(params["download"] == "Download Files")
      @custom_object = params[:custom_objects]
      @files = Dir.glob(session["username"] + '/profiles/*')

      download_files(params)

      return

    else
      @custom_object = params[:custom_objects]
      @files = Dir.glob(session["username"] + '/profiles/*')

      # Deploy the files
      deploy_files(params)

      # Remove the folder
      FileUtils.rm_rf('./' + session["username"])

    end

    respond_to do |format|
      format.html
      format.js
    end

  end

  # Load the files from Salesforce
  def load_files(client, custom_object_name)

    # Set the Manifest file
    manifest = Metaforce::Manifest.new(profile_object_manifest(custom_object_name))

    # retrieve the files
    client.retrieve_unpackaged(manifest)
    .extract_to('./' + session["username"])
    .on_poll {|job| puts job.status}
    .perform

  end

  # Deploy the files
  def deploy_files(params)

    # Get the selected object
    current_object_val = params[:custom_objects]

    # Load the manifest
    manifest = Metaforce::Manifest.new(profile_object_manifest(current_object_val))

    # Create the Array
    profileArr = Array.new

    # Get the profiles and add them to the array
    params[:read].each do |profile|
      profileArr.push(profile[0])
    end

    # Get the hash
    @file_hash = eval(params[:file_hash])


    # Create the XML values
    profileArr.each do |profile|

      # Create the directories
      FileUtils.mkpath './' + file_profile_path
      FileUtils.mkpath './' + file_object_path

      #f = File.open('./' + session["username"] + '/profiles/' + profile + '.profile', "r")
      #file_contents = f.read
      #f.close

      # Create the file paths
      file_path = file_profile_path + profile + ".profile"
      file_name = File.basename(file_profile_path + profile + ".profile", ".profile")

      file_contents = @file_hash[file_path]

      doc = Nokogiri::XML(file_contents)
      doc.remove_namespaces!

      # Get the xml
      allow_read_values = doc.at_css "objectPermissions allowRead"
      allow_edit_values = doc.at_css "objectPermissions allowEdit"
      allow_create_values = doc.at_css "objectPermissions allowCreate"
      allow_delete_values = doc.at_css "objectPermissions allowDelete"
      view_all_values = doc.at_css "objectPermissions viewAllRecords"
      modify_all_values = doc.at_css "objectPermissions modifyAllRecords"

      # Get the selected values
      (params[:read][profile] == "yes") ? allow_read_values.content = 'true' : allow_read_values.content = 'false'

      (params[:edit][profile] == "yes") ? allow_edit_values.content = 'true' : allow_edit_values.content = 'false'

      (params[:create][profile] == "yes") ? allow_create_values.content = 'true' : allow_create_values.content = 'false'

      (params[:delete][profile] == "yes") ? allow_delete_values.content = 'true' : allow_delete_values.content = 'false'

      (params[:view_all][profile] == "yes") ? view_all_values.content = 'true' : view_all_values.content = 'false'

      (params[:modify_all][profile] == "yes") ? modify_all_values.content = 'true' : modify_all_values.content = 'false'

      # Set the namespace
      h1 = doc.at_css "Profile"
      h1["xmlns"] = 'http://soap.sforce.com/2006/04/metadata'

      # Create the new files
      f = File.open('./' + file_profile_path + profile + '.profile', "w")
      new_val = doc.to_xml
      f.puts new_val
      @file_hash[file_path] = new_val
      f.close

    end

    # Create the manifest file
    f = File.open('./' + session["username"] + '/package.xml', "w")
    f.puts manifest.to_xml
    f.close

    # Create the object file
    f = File.open('./' + file_object_path + @custom_object + ".object", "w")

    f.puts @file_hash[params[:file_hash]]

    f.close

    # Deploy the manifest
    #client = Metaforce.new

    Metaforce.configure do |config|

      config.username = session["username"]
      config.password = session["password"]
      config.security_token = session["security_token"]
      config.host = session["host"]
    end

    Metaforce.configuration.log = false

    client = Metaforce.new :username => session["username"],
                           :password => session["password"],
                           :security_token => session["security_token"],
                           :host => session["host"]

    client.deploy(File.expand_path('./' + session["username"]))
    .on_complete { |job| puts "Finished deploy #{job.id}!" }
    .on_error    { |job| puts "Something bad happened!" }
    .on_poll     {
        |job| puts job.status

      #self.response_body  = yield job.status
    }
    .perform
  end

  def create

    # Get the selected object
    current_object_val = params[:custom_objects]

    # Create the Array
    profileArr = Array.new

    # Get the profiles and add them to the array
    params[:read].each do |profile|
      profileArr.push(profile[0])
    end

    # Create the XML values
    profileArr.each do |profile|

      f = File.open("./tmp/profiles/" + profile + ".profile", "r")
      file_contents = f.read
      f.close
      doc = Nokogiri::XML(file_contents)
      doc.remove_namespaces!

      allow_read_values = doc.at_css "objectPermissions allowRead"
      allow_edit_values = doc.at_css "objectPermissions allowEdit"
      allow_create_values = doc.at_css "objectPermissions allowCreate"
      allow_delete_values = doc.at_css "objectPermissions allowDelete"
      view_all_values = doc.at_css "objectPermissions viewAllRecords"
      modify_all_values = doc.at_css "objectPermissions modifyAllRecords"

      # Get the selected values
      (params[:read][profile] == "yes") ? allow_read_values.content = 'true' : allow_read_values.content = 'false'

      (params[:edit][profile] == "yes") ? allow_edit_values.content = 'true' : allow_edit_values.content = 'false'

      (params[:create][profile] == "yes") ? allow_create_values.content = 'true' : allow_create_values.content = 'false'

      (params[:delete][profile] == "yes") ? allow_delete_values.content = 'true' : allow_delete_values.content = 'false'

      (params[:view_all][profile] == "yes") ? view_all_values.content = 'true' : view_all_values.content = 'false'

      (params[:modify_all][profile] == "yes") ? modify_all_values.content = 'true' : modify_all_values.content = 'false'

      h1 = doc.at_css "Profile"
      h1["xmlns"] = 'http://soap.sforce.com/2006/04/metadata'

      f = File.open("./tmp/profiles/" + profile + ".profile", "w")
      f.puts doc.to_xml
      f.close

      client = Metaforce.new
      client.deploy(File.expand_path('./tmp/profiles'))
    end
  end


  def download_files(params)

    # Get the selected object
    current_object_val = params[:custom_objects]

    # Create the Array
    profileArr = Array.new

    # Get the profiles and add them to the array
    params[:read].each do |profile|
      profileArr.push(profile[0])
    end

    # Create the zip file
    Zip::ZipOutputStream::open("Profiles.zip") { |io|

      #Zip::ZipFile.open("MyFile.zip", Zip::ZipFile::CREATE) {|zipfile|
      # Create the XML values
      profileArr.each do |profile|

        # Create the new profile file
        io.put_next_entry(profile + ".profile")

        f = File.open('./' + file_profile_path + profile + '.profile', "r")
        file_contents = f.read
        f.close
        doc = Nokogiri::XML(file_contents)
        doc.remove_namespaces!

        allow_read_values = doc.at_css "objectPermissions allowRead"
        allow_edit_values = doc.at_css "objectPermissions allowEdit"
        allow_create_values = doc.at_css "objectPermissions allowCreate"
        allow_delete_values = doc.at_css "objectPermissions allowDelete"
        view_all_values = doc.at_css "objectPermissions viewAllRecords"
        modify_all_values = doc.at_css "objectPermissions modifyAllRecords"

        # Get the selected values
        (params[:read][profile] == "yes") ? allow_read_values.content = 'true' : allow_read_values.content = 'false'

        (params[:edit][profile] == "yes") ? allow_edit_values.content = 'true' : allow_edit_values.content = 'false'

        (params[:create][profile] == "yes") ? allow_create_values.content = 'true' : allow_create_values.content = 'false'

        (params[:delete][profile] == "yes") ? allow_delete_values.content = 'true' : allow_delete_values.content = 'false'

        (params[:view_all][profile] == "yes") ? view_all_values.content = 'true' : view_all_values.content = 'false'

        (params[:modify_all][profile] == "yes") ? modify_all_values.content = 'true' : modify_all_values.content = 'false'

        h1 = doc.at_css "Profile"
        h1["xmlns"] = 'http://soap.sforce.com/2006/04/metadata'

        io.puts doc.to_xml

      end

    }

    # Download the file
    send_file "Profiles.zip"

  end

# @param [Object] format
  def logout
    session["username"] = ""
    session["password"] = ""
    session["security_token"] = ""
    session["host"] = ""

    respond_to do |format|
      format.html {redirect_to action: "login"}
      #format.js
    end
  end

  def show

  end
end

=begin
  def old_create_zip(params)

    # Get the selected object
    current_object_val = params[:custom_objects]

    # Create the Array
    profileArr = Array.new

    # Get the profiles and add them to the array
    params[:read].each do |profile|
      profileArr.push(profile[0])
    end

    # Create the zip file
    Zip::ZipOutputStream::open("Profiles.zip") { |io|

      #Zip::ZipFile.open("MyFile.zip", Zip::ZipFile::CREATE) {|zipfile|
      # Create the XML values
      profileArr.each do |profile|

        # Create the new profile file
        io.put_next_entry(profile + ".profile")

        # Create the XML and write to the new file
        xml = Builder::XmlMarkup.new(:target=>io, :indent=>2)
        xml.instruct! :xml, :version=>"1.0"

        # Get the selected values
        (params[:read][profile] == "yes") ? allow_read = "true" : allow_read = "false"

        (params[:edit][profile] == "yes") ? allow_edit = "true" : allow_edit = "false"

        (params[:create][profile] == "yes") ? allow_create = "true" : allow_create = "false"

        (params[:delete][profile] == "yes") ? allow_delete = "true" : allow_delete = "false"

        (params[:view_all][profile] == "yes") ? view_all = "true" : view_all = "false"

        (params[:modify_all][profile] == "yes") ? modify_all = "true" : modify_all = "false"

        # Create the Profile XML

        xml.Profile(:xmlns => "http://soap.sforce.com/2006/04/metadata") { |p|
          p.objectPermission { |b|
            b.allowRead(allow_read);
            b.allowEdit(allow_edit);
            b.allowCreate(allow_create);
            b.allowDelete(allow_delete);
            b.modifyAllRecords(modify_all);
            b.viewAllRecords(view_all);
            b.object(current_object_val)
          };
          p.userLicense("Salesforce")
        }

      end

    }

    # Download the file
    send_file "Profiles.zip"
  end
=end



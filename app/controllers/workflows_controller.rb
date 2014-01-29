# Copyright (c) 2012-2013 Cardiff University, UK.
# Copyright (c) 2012-2013 The University of Manchester, UK.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the names of The University of Manchester nor Cardiff University nor
#   the names of its contributors may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Authors
#     Abraham Nieva de la Hidalga
#     Finn Baccall
#     Robert Haines
#     Alan Williams
#
# Synopsis
#
# BioVeL Portal is a prototype interface to Taverna Server provided to support
# easy inspection and execution of workflows.
#
# For more details see http://www.biovel.eu
#
# BioVeL is funded by the European Commission 7th Framework Programme (FP7),
# through the grant agreement number 283359.
class WorkflowsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show, :download]
  before_filter :get_workflows, :only => :index
  before_filter :get_workflow, :only => :show

  # GET /workflows
  # GET /workflows.json
  def index
    @workflows = Workflow.all
    if current_user
      if TavernaLite::WorkflowComponent.all.count>0 && current_user.admin then
        @workflows = Workflow.find(:all,
          :conditions=>['id NOT IN (?)',
            TavernaLite::WorkflowComponent.select(:workflow_id).map(&:workflow_id)])
      else
        @workflows = Workflow.find(:all,
          :conditions=>['id NOT IN (?) AND user_id = ?',
            TavernaLite::WorkflowComponent.select(:workflow_id).map(&:workflow_id),
            current_user.id])
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @workflows }
    end

  end

  # GET /workflows/1
  # GET /workflows/1.json
  def show
    @selected_tab = params[:selected_tab]

    @workflow_profile = TavernaLite::WorkflowProfile.find_by_workflow_id(@workflow)
    if @workflow_profile.nil?
      @workflow_profile = TavernaLite::WorkflowProfile.new()
      @workflow_profile.workflow = @workflow
    end
    @sources, @source_descriptions = @workflow.get_inputs
    @custom_inputs = @workflow_profile.get_custom_inputs
    @custom_outputs = @workflow_profile.get_custom_outputs
    @sinks, @sink_descriptions = @workflow.get_outputs

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @workflow }
    end
  end

  # GET /workflows/new
  # GET /workflows/new.json
  def new
    search_by =""
    if !params[:search].nil?
      # strip removes leading and trailing spaces from string
      search_by = params[:search].strip
    end
    @workflow = Workflow.new
    @me_workflows = []
    @families =[]
    @consumer_tokens=getConsumerTokens
    @services=OAUTH_CREDENTIALS.keys-@consumer_tokens.collect{|c| c.class.service_name}
    if (!search_by.nil? && search_by!="")
      if @consumer_tokens.count > 0
        # search for my experiment workflows
        @workflows = getmyExperimentWorkflows(@me_workflows, URI::encode(search_by))
      end
    end
    if @consumer_tokens.count > 0 && current_user.admin
      # search for my experiment workflows
      @families = getComponentFamilies()
    end
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @workflow }
    end
  end

  # GET /workflows/1/edit
  def edit
    @workflow = Workflow.find(params[:id])
  end

  # POST /workflows
  # POST /workflows.json
  def create
    if(!params[:workflow_name].nil?)
      create_from_my_exp(params)
    else
      create_from_upload(params)
    end
  end
  def create_from_upload(params)
    @workflow = Workflow.new(params[:workflow])
    respond_to do |format|
      @workflow.get_details_from_model
      @workflow.user_id = current_user.id
      # the model uses t2flow to get the data from the workflow file
      if @workflow.save
        format.html { redirect_to @workflow, :notice => 'Workflow was successfully added.' }
        format.json { render :json => @workflow, :status => :created, :location => @workflow }
      else
        format.html { render :action => "new", :notice => 'Workflow cannot be added.' }
        format.json { render :json => @workflow.errors, :status => :unprocessable_entity }
      end
    end
  end
  def create_from_my_exp(params)
    @workflow = Workflow.new()
    content_uri = params[:workflow_uri]
    wf_name = params[:workflow_name]
    wf_name = wf_name.downcase.gsub(" ","_").gsub(".", "") + '.t2flow'
    link_uri = params[:workflow_link]
    @consumer_tokens=getConsumerTokens
    # get the workflow using token
    if @consumer_tokens.count > 0
      token = @consumer_tokens.first.client
      doc = REXML::Document.new(response.body)
      response=token.request(:get, content_uri)

      directory = "/tmp"
      File.open(File.join(directory, wf_name), 'wb') do |f|
        f.puts response.body
      end
    end
    @workflow.me_file = File.open(File.join(directory, wf_name), 'r')
    @workflow.workflow_file = wf_name
    @workflow.my_experiment_id = link_uri
    respond_to do |format|
      @workflow.get_details_from_model
      @workflow.user_id = current_user.id
      # the model uses t2flow to get the data from the workflow file
      if @workflow.save
        format.html { redirect_to @workflow, :notice => 'Workflow was successfully added.' }
        format.json { render :json => @workflow, :status => :created, :location => @workflow }
      else
        format.html { render :action => "new", :notice => 'Workflow cannot be added.' }
        format.json { render :json => @workflow.errors, :status => :unprocessable_entity }
      end
    end
  end
  # PUT /workflows/1
  # PUT /workflows/1.json
  def update
    @workflow = Workflow.find(params[:id])

    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])
        format.html { redirect_to @workflow, :notice => 'Workflow was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @workflow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /workflows/1
  # DELETE /workflows/1.json
  def destroy
    @workflow = Workflow.find(params[:id])
    @workflow.delete_files
    # Dependency to destroy associated records in TL. will disapear if moved to
    # XML file
    tlp = TavernaLite::WorkflowProfile.find_by_workflow_id(@workflow)
    tlports = TavernaLite::WorkflowPort.find_all_by_workflow_id(@workflow)
    tlerrors = TavernaLite::WorkflowError.find_all_by_workflow_id(@workflow)
    unless tlp.nil? then tlp.destroy end
    unless tlports.nil? then tlports.each do |pt| pt.destroy end end
    unless tlerrors.nil? then tlerrors.each do |er| er.destroy end end
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.json { head :no_content }
    end
  end

  def download
    @workflow = Workflow.find(params[:id])
    path = @workflow.workflow_filename
    filetype = 'application/xml'
    send_file path, :type=>filetype , :name => @workflow.name
  end

  def make_public
    @workflow = Workflow.find(params[:id])
    @workflow.shared = true
    @workflow.save!
    redirect_to :back
  end

  def make_private
    @workflow = Workflow.find(params[:id])
    @workflow.shared = false
    @workflow.save!
    redirect_to :back
  end

  def get_family
    nw_family=ComponentFamily.new
    nw_family.id =  params[:id]
    nw_family.name =  params[:name]
    nw_family = get_family_details(nw_family)
    nw_family.components.each {|k,v|
      # get each workflow
      params={:workflow_name=> k,:workflow_uri=>v[3], :workflow_link=>v[2]}
      workflow = download_comp_wfs(params)
      if !workflow.nil?
        # create workflow for each  component
        wfc = TavernaLite::WorkflowComponent.new()
        wfc.workflow_id=workflow.id
        wfc.license_id=1
        wfc.version= v[0]
        wfc.family=nw_family.name
        wfc.name=k
        wfc.registry=nw_family.registry
        wfc.save
      end
      workflow_profile = TavernaLite::WorkflowProfile.find_by_workflow_id(workflow)
      if workflow_profile.nil?
        workflow_profile = TavernaLite::WorkflowProfile.new()
        workflow_profile.workflow = workflow
        # update workflow profile details and add all workflow ports (I/O)
        workflow_profile.description = workflow.description
        workflow_profile.license_id = 1 # default 1
        workflow_profile.title = workflow.title
        workflow_profile.version = v[0]
        workflow_profile.save
      end
      # first get workflow ports
      wf_reader = TavernaLite::T2flowGetters.new
      ports_list = wf_reader.get_workflow_ports(workflow.workflow_filename)
      # update or save ports as needed
      ports_list.each { |port_k, port_v|
        workflow_port = TavernaLite::WorkflowPort.find_by_workflow_id_and_name_and_port_type_id(workflow.id,port_k,port_v.port_type_id)
        if workflow_port.nil?
          port_v.workflow_id = workflow.id
          port_v.save
        else
          workflow_port.depth = port_v.depth
          workflow_port.granular_depth = port_v.depth
        end
     }
    }
    redirect_to :back
  end

  def update_family
    nw_family=ComponentFamily.new
    nw_family.id =  params[:id]
    nw_family.name =  params[:name]
    nw_family = get_family_details(nw_family)
    nw_family.components.each {|k,v|
      # get each workflow
      #v[0] = version, if >1 then call this for each
      count_down = v[0].to_i
      begin
      # if component in right version exists do nothing
      reg_comp = TavernaLite::WorkflowComponent.all(:conditions=>
        ['name = ? AND version = ? AND family = ?', k, count_down, nw_family.name])[0]
      logger.info "Adding Component: #{k} version: #{count_down} results @ #{Time.now}.\n"
      if reg_comp.nil?
      params={:workflow_name=> k, :workflow_uri=>v[3]+"?version=#{count_down}",
        :workflow_link=>v[2], :wf_id=>v[1], :wf_version=> count_down}

      workflow = download_comp_wfs(params)
      if !workflow.nil?
          # if outdated version of component exists
          outdated_comp = TavernaLite::WorkflowComponent.all(:conditions=>
            ['name = ? AND  family = ?', k, nw_family.name])[0]
          #register the most recent version
          # create workflow for each  component
          wfc = TavernaLite::WorkflowComponent.new()
          wfc.workflow_id=workflow.id
          wfc.license_id=1
          wfc.version= count_down
          wfc.family=nw_family.name
          wfc.name=k
          wfc.registry=nw_family.registry
          wfc.save
          # if outdated version of component exists
#          if !outdated_comp.nil?
#            ac=TavernaLite::AlternativeComponent.new
#            ac2=TavernaLite::AlternativeComponent.new
#            ac.component_id=outdated_comp.id
#            ac.alternative_id=wfc.id
#            ac.note="new versions are by default considered as equivalent"
#            ac2.component_id=wfc.id
#            ac2.alternative_id=outdated_comp.id
#            ac2.note="new versions are by default considered as equivalent"
#            ac.save
#            ac2.save
#          end
        workflow_profile = TavernaLite::WorkflowProfile.find_by_workflow_id(workflow)
        if workflow_profile.nil?
          workflow_profile = TavernaLite::WorkflowProfile.new()
          workflow_profile.workflow = workflow
          # update workflow profile details and add all workflow ports (I/O)
          workflow_profile.description = workflow.description
          workflow_profile.license_id = 1 # default 1
          workflow_profile.title = workflow.title
          workflow_profile.version = v[0]
          workflow_profile.save
        end
        # first get workflow ports
        wf_reader = TavernaLite::T2flowGetters.new
        ports_list = wf_reader.get_workflow_ports(workflow.workflow_filename)
        # update or save ports as needed
        ports_list.each { |port_k, port_v|
          workflow_port = TavernaLite::WorkflowPort.find_by_workflow_id_and_name_and_port_type_id(workflow.id,port_k,port_v.port_type_id)
          if workflow_port.nil?
            port_v.workflow_id = workflow.id
            port_v.save
          else
            workflow_port.depth = port_v.depth
            workflow_port.granular_depth = port_v.depth
            workflow_port.save
          end
        }
        end
      end
      count_down -= 1
      end while count_down>=1
    }
    redirect_to :back
  end

  def download_comp_wfs(params)
    workflow = Workflow.new()
    content_uri = params[:workflow_uri]
    wf_version = params[:wf_version]
    wf_id = params[:wf_id]
    wf_name = params[:workflow_name]
    wf_name = wf_name.downcase.gsub(" ","_").gsub(".", "") + '.t2flow'
    link_uri = params[:workflow_link]
    # http://www.myexperiment.org/workflows/3640/versions/1/
#    logger.info "http://www.myexperiment.org/workflows/#{wf_id}/versions/#{wf_version}"
#    content_uri = "http://www.myexperiment.org/workflows/#{wf_id}/versions/#{wf_version}"
# Problem when getting older versions of components as they are not always
# retrievable using the same methods as the most recent workflow

    @consumer_tokens=getConsumerTokens
    # get the workflow using token
    if @consumer_tokens.count > 0
      token = @consumer_tokens.first.client
      doc = REXML::Document.new(response.body)
      response=token.request(:get, content_uri)
      if response.body.nil?
        logger.info "body for workflow #{wf_id} versions #{wf_version} is nil"
        return nil
      end
      if response.body==""
        logger.info "body for workflow #{wf_id} versions #{wf_version} is empty
          string"
        return nil
      end
      directory = "/tmp"
      File.open(File.join(directory, wf_name), 'wb') do |f|
        f.puts response.body
      end
    end
    workflow.me_file = File.open(File.join(directory, wf_name), 'r')
    workflow.workflow_file = wf_name
    workflow.my_experiment_id = link_uri
    workflow.get_details_from_model
    workflow.user_id = current_user.id
    if workflow.save
      return workflow
    else
      return nil
    end
  end

  private

  def get_workflows
    @shared_workflows = Workflow.find_all_by_shared(true)
    if !current_user.nil?
      @workflows = Workflow.all
      if !current_user.admin
        @workflows.delete_if {|wkf| wkf.user_id != current_user.id}
      end
    end
  end

  def get_workflow
    @workflow = Workflow.find(params[:id])
    if current_user.nil?
      return authenticate_user! if !@workflow.shared?
    else
      return authenticate_user! if @workflow.user_id != current_user.id
    end
  end

  def getConsumerTokens
    MyExperimentToken.all :conditions=> {:user_id=>current_user.id}
  end

  def getmyExperimentWorkflows(workflows=[], search_by="")
    consumer_tokens = getConsumerTokens
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # URI for the packs, will return all the packs for selected page
      # PROBLEM: how do we know how many pages are there?
      workflow_uri = "http://www.myexperiment.org/search.xml?query='" + search_by
      workflow_uri += "'&type=workflow&num=100&page="
      # Get the workflows using the request token
      no_workflows = false
      page = 1
      begin
        response=token.request(:get, workflow_uri+ page.to_s)
        doc = REXML::Document.new(response.body)
        if doc.elements['search/workflow'].nil? ||
           doc.elements['search/workflow'].has_elements?
          no_workflows = true
        else
          doc.elements.each('search/workflow') do |p|
            p.attributes.each do |attrbt|
              if(attrbt[0]=='resource')
                nw_workflow=MeWorkflow.new
                nw_workflow.my_exp_id = attrbt[1].to_s.split('/').last
                if get_workflow_permissions(nw_workflow).include?("download")
                  nw_workflow.name = p.text
                  nw_workflow.id = nw_workflow.my_exp_id
                  nw_workflow.uri = attrbt[1]
                  nw_workflow = download_my_exp_workflow(nw_workflow)
                  if nw_workflow.type == "Taverna 2"
                    workflows << nw_workflow
                  end
                end
              end
            end
          end
          page +=1
        end
      end while no_workflows == false
    end
    return workflows
  end

  def download_my_exp_workflow(workflow)
    consumer_tokens=getConsumerTokens
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # URI for the packs, will return all the packs for selected page
      # PROBLEM: how do we know how many pages are there?
      workflow_uri = "http://www.myexperiment.org/workflow.xml?id=" +
                  workflow.id.to_s
      # Get the workflow using the request token
      response=token.request(:get, workflow_uri)
      doc = REXML::Document.new(response.body)
      workflow.name = doc.elements['workflow/title'].text
      workflow.content_uri = get_workflow_content_uri(workflow)
      workflow.description = doc.elements['workflow/description'].text
      workflow.type = doc.elements['workflow/type'].text
      # get permisions
      permissions = get_workflow_permissions(workflow)
      workflow.can_download = permissions.include?("download")
    end
    return workflow
  end

  def get_workflow_content_uri(workflow)
    consumer_tokens = getConsumerTokens
    content_uri =""
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # URI for the workflow
      workflow_uri =  "http://www.myexperiment.org/workflow.xml?id="
      workflow_uri += workflow.my_exp_id.to_s
      workflow_uri += '&elements=content-uri'
      response=token.request(:get, workflow_uri)
      doc = REXML::Document.new(response.body)
      doc.elements.each('workflow/content-uri') do |u|
        content_uri = u.text
      end
    end
    return content_uri
  end
  # do not include workflows that cannot be downloaded in the results
  def get_workflow_permissions(workflow)
    consumer_tokens = getConsumerTokens
    elements = []
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # URI for the workflow
      workflow_uri =  "http://www.myexperiment.org/workflow.xml?id="
      workflow_uri += workflow.my_exp_id.to_s
      workflow_uri += '&elements=privileges'
      response=token.request(:get, workflow_uri)
      doc = REXML::Document.new(response.body)
      doc.elements.each('workflow/privileges/privilege') do |u|
        u.attributes.each do |attrbt|
          if(attrbt[0]=='type')
            elements << attrbt[1]
          end
        end
      end
    end
    return elements
  end  #search for component families in the registry

  ##############################################################################
  # Code for adding and managing workflow component families
  # Need to be moved to Taverna Lite, it is here only temporarily because this
  # app already has connectivity to my experiment
  ##############################################################################
  class ComponentFamily
  # A model for workflow component families
    attr_accessor :id, :my_exp_id, :name, :pack_id, :uri, :content_uri, :title,
      :description, :type, :can_download, :registry, :components, :used,
      :needs_update
    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end
    def self.all
      families = []
    end
  end

  def getComponentFamilies(families=[])
    consumer_tokens = getConsumerTokens
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # apparently componets are not paginated but left comments in ocde in case
      # later they are
      families_uri = "http://www.myexperiment.org/component-families.xml"#?page="
      # Get the workflows using the request token
      no_families = false
      #page = 1
      #begin
        response=token.request(:get, families_uri)#+ page.to_s)
        doc = REXML::Document.new(response.body)
        puts doc.root.elements.count
        if doc.elements['component-families/pack'].nil? ||
           doc.elements['component-families/pack'].has_elements?
          no_families = true
        else
          doc.elements.each('component-families/pack') do |p|
            p.attributes.each do |attrbt|
              if(attrbt[0]=='resource')
                nw_family=ComponentFamily.new
                nw_family.my_exp_id = attrbt[1].to_s.split('/').last
                if get_family_permissions(nw_family).include?("download")
                  nw_family.name = p.text
                  nw_family.id = nw_family.my_exp_id
                  nw_family.uri = attrbt[1]
                  nw_family = get_family_details(nw_family)
                  # for now this is the only registry
                  nw_family.registry = "http://www.myexperiment.org"
                  unless nw_family.components == {}
                    families << nw_family
                  end
                end
              end
            end
          end
          #page +=1
        end
      #end while no_families == false
    end
    return families
  end

  def get_family_permissions(family)
    consumer_tokens = getConsumerTokens
    elements = []
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # URI for the workflow
      family_uri =  "http://www.myexperiment.org/component-family.xml?id="
      family_uri += family.my_exp_id.to_s
      family_uri += '&elements=privileges'
      response=token.request(:get, family_uri)
      doc = REXML::Document.new(response.body)
      doc.elements.each('pack/privileges/privilege') do |u|
        u.attributes.each do |attrbt|
          if(attrbt[0]=='type')
            elements << attrbt[1]
          end
        end
      end
    end
    return elements
  end

  def get_family_details(family)
    consumer_tokens=getConsumerTokens
    if consumer_tokens.count > 0
      token = consumer_tokens.first.client
      # URI for the packs, will return all the packs for selected page
      # PROBLEM: how do we know how many pages are there?
      family_uri = "http://www.myexperiment.org/component-family.xml?id=" +
                  family.id.to_s
      # Get the workflow using the request token
      response=token.request(:get, family_uri)
      doc = REXML::Document.new(response.body)
      family.name = doc.elements['pack/title'].text
      family.description = doc.elements['pack/description'].text
      # get permisions
      permissions = get_family_permissions(family)
      family.can_download = permissions.include?("download")
      family.components = list_family_components(doc, family, token)
      comps=TavernaLite::WorkflowComponent.find_by_family(family.name)
      family.used=!comps.nil?
      family.needs_update = family_needs_updating(family)
      family.registry="http://www.myexperiment.org"
    end
    return family
  end
  def list_family_components(doc, family, token)
    components = {}
    if !doc.elements["pack/internal-pack-items/workflow"].nil?
      doc.elements.each("pack/internal-pack-items/workflow") { |wf|
        #puts wf.text + " " + wf.attributes["resource"].to_s.split('/').last
        wf_id = wf.attributes["resource"].to_s.split('/').last
        workflow_uri =  "http://www.myexperiment.org/workflow.xml?id="
        workflow_uri += wf_id
        response=token.request(:get, workflow_uri)
        wfdoc = REXML::Document.new(response.body)
        #puts wfdoc.root.attributes["version"]
        # non authorised gives blanks do not add
        unless wfdoc.root.name == 'error'
          components[wf.text] = [wfdoc.root.attributes["version"],
                                 wfdoc.root.attributes["id"],
                                 wfdoc.root.attributes["resource"],
                                 wfdoc.root.elements["content-uri"].text]
        end
      }
    end
    return components
  end
  def family_needs_updating(family)
    # for now just check if family is registered in TL
    # for each component in the family:
    # check all components exist and that their versions are the latest version
    comps=TavernaLite::WorkflowComponent.find_all_by_family(family.name)
    if !comps.nil? && comps.count > 0
      # check that all versions are registered locally...
      versions = 0
      family.components.each {|k,v|
        versions += v[0].to_i
      }
      if versions != comps.count
        return true # There are version which have not been registered locally
      end
#      # first check if the number of components is ok
#      if family.components.count!=comps.count
#        return true # needs updating
#      end
      # now check if the versions are up to date
      family.components.each { |c_name, c_ver|
        c=TavernaLite::WorkflowComponent.find_by_name_and_version(c_name, c_ver)
        if c.nil?
          return true # a component is missing needs updating
        end
      }
    end
    return false
  end


end

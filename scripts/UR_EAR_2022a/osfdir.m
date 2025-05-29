function attr = osfdir(project_node,varargin)
%osfdir: Return attributes for items in an OSF project and optional subfolder.
%  Syntax:
%    attr = osfdir(project)
%    attr = osfdir(project,subfolder1)
%    attr = osfdir(project,subfolder1,subfolder2,...)
%  where,
%    project is the project node ID, e.g., '6bsnt'
%    subfolder1, etc. are names of (possibly nested) folders within the project
%    attr is a structure array of attributes with the following fields:
% 		guid                     (char) unique ID
% 		checkout                 (double) empty
% 		name                     (char) file or folder name
% 		kind                     (char) 'file' or 'folder'
% 		path                     (char) path
% 		size                     (double) size in bytes (empty for folders)
% 		provider                 (char) 'osfstorage'
% 		materialized_path        (char) partial path
% 		last_touched             (double) empty
% 		date_modified            (char) date modified (UTC) (empty for folders)
% 		date_created             (char) date created (UTC) (empty for folders)
% 		extra                    (struct) 2 fields:
%			hashes
%			downloads (files only)
% 		tags                     (double) empty
% 		current_user_can_comment (logical) false
% 		current_version          (double) version number
% 		links                    (struct) 8 fields for files (all char):
%			info: JSON for this file
%			move
%			upload
%			delete
%			download: use this URL to download file
%			render: use this URL to render (display) file, such as a PDF
%			html: OSF page for this file
%			self: same as info
%			                     6 fields for folders (all char):
%			info: JSON for this folder
%			move
%			upload
%			delete
%			new_folder
%			self: same as info

% Author: Doug Schwarz
% Email: douglas.schwarz@rochester.edu
% Date: 3 April 2022

% Check arguments.  First argument must be convertible to a string.
arguments
	project_node (1,1) string {mustBeText} = "6bsnt"
end

% Subsequent arguments must be convertible to strings.
arguments (Repeating)
	varargin (1,1) string {mustBeText}
end

% Build base URL to files/osfstorage for specified node (project).
URL_base = "https://api.osf.io/v2/nodes/" + project_node + "/files/osfstorage/";
URL = URL_base;

% Loop through list of subfolders, appending to path in URL.  First time through
% the loop (when level = 0), use base URL.
num_sublevels = length(varargin);
for level = 0:num_sublevels
	% Find subfolder in attr and append its path to URL.
	if level > 0
		index = find(strcmp({attr.kind},'folder') & ...
			strcmp({attr.name},varargin{level}));
		if isempty(index)
			error('Folder "%s" not found.',varargin{level})
		end
% 		URL = strip(URL,"right","/") + attr(index).path;
		URL = strip(URL_base,"right","/") + attr(index).path;
	end
	
	% Construct message, send it, get response, and check for an error.
	message = matlab.net.http.RequestMessage;
	uri = matlab.net.URI(URL);
	response = message.send(uri);
	if response.StatusCode ~= 200 % status code 200 means 'OK'.
		error('Node "%s": %s',project_node,response.StatusLine.ReasonPhrase)
	end
	
	% Decode JSON data string into a structure.
	json_struct = jsondecode(response.Body.Data);
	
	% Get attributes and add a links field.
	attr = [json_struct.data.attributes];
	links_c = {json_struct.data.links};
	[attr.links] = links_c{:};
end

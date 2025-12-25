local folder = "cloud9file"

if isfolder and delfolder then
	if isfolder(folder) then
		delfolder(folder)
	else
		warn("Folder not found")
	end
else
	warn("Executor does not support folder functions")
end

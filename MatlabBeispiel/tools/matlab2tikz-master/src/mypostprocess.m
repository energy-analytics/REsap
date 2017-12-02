function mypostprocess(filename)
fid=fopen(filename);
fidnew=fopen(strcat(filename, '.tmp'),'w+');
while(~feof(fid)); 
    s=fgetl(fid);
    fprintf(fidnew, '%s\n',s);
    if strcmp(s, '\begin{axis}[%')
        fprintf(fidnew, '%s\n',' /pgf/number format/.cd,');
        fprintf(fidnew, '%s\n','        use comma,');
        fprintf(fidnew, '%s\n','        1000 sep={},');
    end
end
fclose(fid);
fclose(fidnew);
delete(filename);
movefile(strcat(filename,'.tmp'),filename);
fprintf('%s\n', '>> My dirty postprocessing is done!');


function m2l(filename,varargin)
% Author: Pascal Dubucq, 2016
%
% M2L(FILENAME)  Saves the current figure as an EPS file, and produces a
% latex file that calls that figure and can directly be included in a latex
% document. All paths are hard coded therefore this will currently work
% only for me...
%
args=varargin;
% save eps to eps folder
if nargin>1
    basepath=args{1};
else
    basepath='d:\Dropbox\Dissertation\Tex';
end
epspath=strcat(basepath, '\figures\');
set(gcf,'PaperPositionMode','auto');
%print(gcf, '-depsc','-opengl','-r600', strcat(epspath, filename, '.eps'));
if nargin>2
    export_fig(strcat(epspath, filename, '.eps'), args{2})
else 
    export_fig(strcat(epspath, filename, '.eps'), '-q101')
end
% copy latex template if no latex file present
latexpath=strcat(basepath, '\latexfigtab\');
latexfilename=strcat(latexpath,filename, '.tex');
if exist(latexfilename, 'file') ~= 2
    copyfile(which('m2l.tex'), latexfilename);
    % replace placeholders with new name
    fid=fopen(latexfilename);
    tmpfile=strcat(latexfilename, '.tmp');
    fidnew=fopen(tmpfile,'w+');
    while(~feof(fid)); 
        s=fgetl(fid);
        s=strrep(s, 'xxx', filename);
        s=strrep(s, 'yyy', strrep(filename,'_',' '));
        fprintf(fidnew, '%s\n',s);
    end
    fclose(fid);
    fclose(fidnew);
    delete(latexfilename);
    movefile(tmpfile,latexfilename);
end
clipboard('copy', strcat('\input{latexfigtab/',filename,'}'));
%system('d:\Dropbox\Dissertation\Tex\latexfigtab\_figuretester.tex');

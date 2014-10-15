fileID = fopen('nregparams.txt','w');

fprintf(fileID,'#\r\n');
fprintf(fileID,'# Registration Parameters\r\n');
fprintf(fileID,'#\r\n\r\n');
fprintf(fileID,'No. of resolution levels\t= 2\r\n\r\n');
fprintf(fileID,'No. of bins             \t= 64\r\n');
fprintf(fileID,'Epsilon            \t\t= 0.01\r\n');
fprintf(fileID,'Padding value      \t\t= -1\r\n');
fprintf(fileID,'Similarity measure\t\t= NMI\r\n');
fprintf(fileID,'Interpolation mode\t\t= Linear\r\n');
fprintf(fileID,'Optimization method\t\t= GradientDescent\r\n');

fclose(fileID);
function save_figure(filename)

[~, ~, savepath, ~] = get_paths();
print(fullfile(savepath, [filename '.png']),'-dpng', '-r600')
% print('-vector', fullfile(savepath, '2025-manuscript', [filename '.tif']),...
% 	'-dtiff', '-r600')
% print('-vector', fullfile(savepath, '2025-manuscript', [filename '.eps']),...
% 	'-depsc', '-r600')

end
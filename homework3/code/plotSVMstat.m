function plotSVMstat(stats)

energy = stats{1};
diag_freq = stats{2};

figure
hold on
plot(energy(1,:),'--b') ;
plot(energy(2,:),'-.g') ;
plot(energy(3,:),'r') ;
plot(energy(4,:),'y') ;
legend('Primal objective','Dual objective','Duality gap','loss')
xlabel({'Diagnostics iteration',['(freq=',num2str(diag_freq),')']})
ylabel('Energy')

end
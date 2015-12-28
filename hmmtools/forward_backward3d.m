function [forward_probabilities, backward_probabilities, normalization_factors] =...
         forward_backward3d(packed_3d_hmm, seq1, seq2, seq3)


  [tr1, tr2, tr3,  em1, em2, em3] = unpack3DHMM(packed_3d_hmm);
  num_states1 = size(tr1, 1);
  num_states2 = size(tr2, 1);
  num_states3 = size(tr3, 1);  

  % add extra symbols to start to make algorithm cleaner at f0 and b0
  seq1 = [1, seq1];
  seq2 = [1, seq2];
  seq3 = [1, seq3];  
  L = length(seq1);

  forward_probabilities = zeros(num_states1, num_states2, num_states3, L);
  forward_probabilities(1,1,1,1) = 1;
  normalization_factors = zeros(1, L);
  normalization_factors(1) = 1;
  for count = 2:L
    for state1 = 1:num_states1
      for state2 = 1:num_states2
        for state3 = 1:num_states3
          forward_probabilities(state1, state2, state3, count) = ...
          em1(state1, seq1(count)) * em2(state2, seq2(count)) * em3(state3, seq3(count)) * ...
          sum(sum(sum(forward_probabilities(:,:,:,count-1) .* ...
                      squeeze(tr1(state1, :, :, :)) .* ...
                      permute(squeeze(tr2(state2, :, :, :)), [3, 1, 2]) .* ...
                      permute(squeeze(tr3(state3, :, :, :)), [2, 3, 1])  )));
        end
      end
    end
    normalization_factors(count) = sum(sum(sum(forward_probabilities(:,:,:, count))));
    forward_probabilities(:,:,:, count) = ...
    forward_probabilities(:,:,:, count)./normalization_factors(count);
  end


  backward_probabilities = ones(num_states1, num_states2, num_states3, L);
  for count = L-1:-1:1
    for state1 = 1:num_states1
      for state2 = 1:num_states2
        for state3 = 1:num_states3
          backward_probabilities(state1, state2, state3, count) = ...
          sum(sum(sum(...
                       repmat(em1(:,seq1(count+1)), [1, num_states2, num_states3]) .* ...
                      permute(repmat(em2(:,seq2(count+1)), [1, num_states3, num_states1]), ...
                              [3, 1, 2]) .* ...
                      permute(repmat(em3(:,seq3(count+1)), [1, num_states1, num_states2]), ...
                              [2, 3, 1]) .* ...
                      ...
                      backward_probabilities(:,:,:, count+1) .* ...
                      ...
                      repmat(squeeze(tr1(:, state1, state2, state3)), ...
                             [1, num_states2, num_states3]) .* ...
                      permute(repmat(squeeze(tr2(:, state2, state3, state1)), ...
                                     [1, num_states3, num_states1]), [3 1 2]) .* ...
                      permute(repmat(squeeze(tr3(:, state3, state1, state2)), ...
                                     [1, num_states1, num_states2]), [2 3 1]))));
        end
      end
    end
    backward_probabilities(:,:,:,count) = ...
    backward_probabilities(:,:,:,count)./normalization_factors(count+1);
  end 


%  for count = L-1:-1:1
%    for state1 = 1:num_states1
%      for state2 = 1:num_states2
%        for state3 = 1:num_states3
%          backward_probabilities(state1, state2, state3, count) = 0;
%          for fstate1 = 1:num_states1
%            for fstate2 = 1:num_states2
%              for fstate3 = 1:num_states3
%                  backward_probabilities(state1, state2, state3, count) = ...
%                  backward_probabilities(state1, state2, state3, count) + ...
%                      backward_probabilities(fstate1, fstate2, fstate3, count+1) * ...
%                  em1(fstate1, seq1(count+1)) * em2(fstate2, seq2(count+1)) * ...
%                  em3(fstate3, seq3(count+1)) * tr1(fstate1, state1, state2, state3) * ...
%                  tr2(fstate2, state2, state3, state1) * tr3(fstate3, state3, state1, state2);
%              end
%            end
%          end
%        end
%      end
%    end
%    backward_probabilities(:,:,:,count) = ...
%    backward_probabilities(:,:,:,count)./normalization_factors(count+1);
%  end 
%  
%
%
%

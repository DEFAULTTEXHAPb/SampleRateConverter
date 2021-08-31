clear all;
TEST_VECTOR_LENGTH = 64;

for i = 1 : 16
    a   = rand(1,TEST_VECTOR_LENGTH)-0.5;
    a_f = fi(a,1,32,31);
    b   = rand(1,TEST_VECTOR_LENGTH)-0.5;
    b_f = fi(b,1,32,31);
    c_f(i)  = fixed_FIR_MAC(a_f, b_f);
    c(i)    = FIR_MAC(a, b);
end
disp(c_f);
disp(c);
function c_f = fixed_FIR_MAC(dataf, coef)
    if (length(dataf) ~= length(coef))
        error("Data and Coefficient vectors must have the same length");
    end
    c_f = fi(0,1,32,31);
    for i = 1 : length(dataf)
        %c_f = fi((dataf(i).*coef(i) + c_f),1,32,31);
        c_f = dataf(i).*coef(i) + c_f;
    end
end

function c = FIR_MAC(data, coe)
    if (length(data) ~= length(coe))
        error("Data and Coefficient vectors must have the same length");
    end
    c = 0;
    for i = 1 : length(data)
        c = data(i).*coe(i) + c;
    end
end
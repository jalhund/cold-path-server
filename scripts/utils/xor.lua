function repeat_key(key, length)
    if #key >= length then
        return key:sub(1, length)
    end

    times = math.floor(length / #key)
    remain = length % #key

    result = ''

    for i = 1, times do
        result = result .. key
    end

    if remain > 0 then
        result = result .. key:sub(1, remain)
    end

    return result
end

local function BitXOR(a,b)--Bitwise xor
    local p,c=1,0
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra~=rb then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    if a<b then a=b end
    while a>0 do
        local ra=a%2
        if ra>0 then c=c+p end
        a,p=(a-ra)/2,p*2
    end
    return c
end


function xor(message, key)
    rkey = repeat_key(key, #message)

    result = ''

    for i = 1, #message do
        k_char = rkey:sub(i, i)
        m_char = message:sub(i, i)

        k_byte = k_char:byte()
        m_byte = m_char:byte()

        xor_byte = BitXOR(m_byte, k_byte)

        xor_char = string.char(xor_byte)

        result = result .. xor_char
    end

    return result
end

return xor